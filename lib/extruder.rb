require 'json'
require 'openssl'
require 'singleton'
require 'tempfile'
require 'yaml'

require 'extruder/processor'

module Extruder

  # This class holds configuration data for Extruder.
  class Config
    attr_reader :processors, :cache_tag

    # Load the configuration from the given file, or if no file is given, the
    # default configuration file.
    #
    # @param file [String or IO] the name of the file to load (or an IO object)
    # @param options [Hash] additional per-invocation options
    def initialize(file = nil, options = {})
      file = '/etc/extruder/extruder.conf' if file.nil?
      file = File.new(file, 'r:UTF-8') unless file.respond_to? :read

      config = YAML.load(file)
      @locations = {}
      [:queue, :processors].each { |x|
        @locations[x] = config['locations'][x.to_s]
      }
      @processors = config['processors'].map { |x|
        result = {}
        [:require, :name, :args, :config].each { |option|
          next unless x.key? option.to_s
          result[option] = x[option.to_s]
        }
        result
      }
      @cache_tag = options[:cache_tag]
    end

    # Get the file system location for the given component.
    #
    # Currently, the only valid component is :queue.
    def location(type)
      @locations[type]
    end
  end

  class InvalidDigestError < StandardError
  end

  class Store
    # Note that some methods of this class are in a separate module to avoid the
    # overhead of loading all the MIME types when they're not needed.

    def create
      Dir.mkdir(@location, 0755)
      typedir = File.join(@location, @type)
      Dir.mkdir(typedir, 0755)
      (0..255).each { |x|
        Dir.mkdir(File.join(typedir, "%02x" % x), 01773)
      }
      tmpdir = File.join(typedir, "tmp")
      Dir.mkdir(tmpdir, 03733)
      File.chmod(03733 & ~File.umask, tmpdir)
    end

    protected
    def location
      File.join(@location, @type)
    end

    def dirname(m)
      if m.respond_to? :digest_as_hex
        piece = m.digest_as_hex
      else
        piece = m
      end
      File.join(location, piece[0..1])
    end

    def filename(m)
      digest = m.digest_as_hex
      File.join(dirname(digest), digest[2..-1])
    end
  end

  class Queue < Store
    def initialize(directory)
      @location = directory
      @type = "queue"
    end

    def inject(item, tags)
      file = Tempfile.new('item', File.join(@location, 'queue', 'tmp'))
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
      destination = File.join(@location, @type, dir, name)
      File.rename(file.path, destination)
      metafile = Tempfile.new('metadata', File.join(@location, @type, 'tmp'))
      metafile << JSON.generate(tags: tags)
      File.rename(metafile.path, "#{destination}.meta")
    end
  end

  class ProcessorRegistry
    include Singleton
    include Enumerable

    def initialize
      @processors = {}
    end

    # Register a processor.
    #
    # @param klass the processor class object
    # @param name [String, Symbol] an identifier by which the processor can be
    #   looked up
    def register(klass, name)
      @processors[name] = klass
    end

    # Iterate over the processors
    def each
      @processors.each { |x| yield x }
    end

    # Look up a processor by name.
    #
    # @param name [String, Symbol] the name of the processor
    # @return [Class, nil] the processor's class or nil if not found
    def lookup(name)
      @processors[name]
    end
  end
end
