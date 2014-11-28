require 'mail'

module Extruder
  class FileStub
    def initialize(file, mode)
      @file = file
      @mode = mode
      @obj = nil
    end

    def file
      return @obj if obj
      @obj = File.new(@file, @mode)
    end
  end

  class Message
    attr_accessor :metadata, :digest, :original_message
    attr_writer :message

    def initialize(msg, metadata, digest = nil)
      @msg = msg
      @metadata = metadata
      set_digest(msg, digest)
    end

    def digest_as_hex
      @digest.unpack('H*')[0]
    end

    def message
      return @message unless @message.nil?

      if @msg.is_a?(Mail::Message)
        @message = @msg
      else
        @message = Mail.read_from_string(string_message)
      end
    end

    def original_message
      @original_message ||= string_message
    end

    private

    def string_message
      load_message
      if @msg.is_a?(String)
        @msg
      elsif @msg.respond_to? :read
        @msg = @msg.read
      end
    end

    def load_message
      if @msg.is_a?(FileStub)
        @msg = @msg.file
      end
    end

    def set_digest(msg, digest)
      if digest.nil?
        if msg.is_a?(String)
          hash = OpenSSL::Digest::SHA256.new
          hash << msg
          @digest = hash.digest
        else
          fail InvalidDigestError, 'a digest is required'
        end
      elsif digest.length == 32
        @digest = digest
      elsif digest.length == 64
        if digest !~ /\A[a-fA-F0-9]{64}\z/
          fail InvalidDigestError, 'digest must be a valid SHA-256 value'
        end
        @digest = [digest].pack('H*')
      else
        fail InvalidDigestError, 'digest must be a valid SHA-256 value'
      end
    end
  end

  class Store
    include Enumerable

    def each
      unless @messages.nil?
        @messages.each { |x| yield x }
        return
      end

      @messages = []

      (0..255).each do |x|
        piece = '%02x' % x
        dir = Dir.new(dirname(piece))
        opts = {create_additions: false, symbolize_names: true}

        # TODO: validate the SHA-256 value.
        files = dir.each.sort.select { |file| /\A[0-9a-f]{62}\z/ =~ file }
        files.each do |component|
          file = File.join(dir.path, component)
          metadata = JSON.load(File.new("#{file}.meta", 'r:UTF-8'), nil, opts)
          m = Message.new FileStub.new(file, 'rb'), metadata,
                          "#{piece}#{component}"
          @messages << m
          yield m
        end
      end
    end

    def save_metadata
      return unless @messages

      @messages.each do |m|
        f = File.new("#{filename(m)}.meta", 'w:UTF-8')
        JSON.dump(m.metadata, f)
      end
    end
  end
end
