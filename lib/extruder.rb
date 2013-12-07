require 'json'
require 'openssl'
require 'tempfile'
require 'yaml'

require 'extruder/processor'

module Extruder

  # This class holds configuration data for Extruder.
  class Config

    # Load the configuration from the given file, or if no file is given, the
    # default configuration file.
    def initialize(filename = nil)
      if filename.nil?
        filename = '/etc/extruder/extruder.conf'
      end

      config = YAML.load_file(filename)
      @locations = {}
      [:queue].each { |x|
        @locations[x] = config['locations'][x.to_s]
      }
      @processors = config['processors'].map { |x|
        result = {}
        [:require, :name, :args, :config].each { |option|
          result[option] = x[option.to_s]
        }
        result
      }
    end

    # Get the file system location for the given component.
    #
    # Currently, the only valid component is :queue.
    def location(type)
      @locations[type]
    end

    # Get the list of processors.
    #
    # Processors will be run in the order that they are specified here.
    def processors
      @processors
    end
  end

  class InvalidDigestError < StandardError
  end

  class Message
    attr_accessor :message, :metadata, :digest

    def initialize(msg, metadata, digest = nil)
      if msg.is_a?(String)
        @message = Mail.new msg
      else
        @message = msg
      end
      @metadata = metadata
      if digest.nil?
        if msg.is_a?(String)
          hash = OpenSSL::Digest::SHA256.new
          hash << msg
          @digest = hash.digest
        else
          raise InvalidDigestError.new "a digest is required"
        end
      elsif digest.length == 32
        @digest = digest
      elsif digest.length == 64
        @digest = [digest].pack("H*")
      else
        raise InvalidDigestError.new "digest must be a valid SHA-256 value"
      end
    end

    def digest_as_hex
      @digest.unpack('H*')[0]
    end
  end

  class Store
    include Enumerable

    def create
      Dir.mkdir(@location, 0755)
      Dir.mkdir("#{@location}/#{@type}", 0755)
      (0..255).each { |x|
        Dir.mkdir("#{@location}/#{@type}/#{"%02x" % x}", 01773)
      }
      Dir.mkdir("#{@location}/#{@type}/tmp", 03733)
    end

    def each
      location = "#{@location}/#{@type}"
      (0..255).each do |x|
        piece = "%02x" % x
        dir = Dir.new("#{location}/#{piece}")
        json_opts = {create_additions: false, symbolize_names: true}

        # TODO: validate the SHA-256 value.
        files = dir.each.sort.select { |file| /\A[0-9a-f]{62}\z/ =~ file }
        files.each do |component|
          file = "#{dir.path}/#{component}"
          metadata = JSON.load(File.new("#{file}.meta"), nil, json_opts)
          yield Message.new Mail.read(file), metadata, "#{piece}#{component}"
        end
      end
    end
  end

  class Queue < Store
    def initialize(directory)
      @location = directory
      @type = "queue"
    end

    def inject(item, tags)
      file = Tempfile.new('item', "#{@location}/queue/tmp")
      digest = OpenSSL::Digest::SHA256.new
      if item.respond_to?(:each)
        item.each { |x| 
          digest << x
          file << x
        }
      else
        s = item.to_s
        digest << s
        file << s
      end
      hexdigest = digest.digest.unpack('H*')[0]
      dir, name = hexdigest[0..1], hexdigest[2..64]
      destination = "#{@location}/#{@type}/#{dir}/#{name}"
      File.rename(file.path, destination)
      metafile = Tempfile.new('metadata', "#{@location}/#{@type}/tmp")
      metafile << JSON.generate({tags: tags})
      File.rename(metafile.path, "#{destination}.meta")
    end
  end
end
