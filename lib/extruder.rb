require 'json'
require 'openssl'
require 'tempfile'
require 'yaml'

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
    end

    # Get the file system location for the given component.
    #
    # Currently, the only valid component is :queue.
    def location(type)
      @locations[type]
    end
  end

  class Store
    def create
      Dir.mkdir(@location, 0755)
      Dir.mkdir("#{@location}/#{@type}", 0755)
      (0..255).each { |x|
        Dir.mkdir("#{@location}/#{@type}/#{"%02x" % x}", 01773)
      }
      Dir.mkdir("#{@location}/#{@type}/tmp", 03733)
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
      if item.respond_to?(each)
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
