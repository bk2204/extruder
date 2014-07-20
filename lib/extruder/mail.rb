require 'mail'

module Extruder
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
      if @msg.is_a?(String)
        @msg
      elsif @msg.respond_to? :read
        @msg = @msg.read
      end
    end

    def set_digest(msg, digest)
      if digest.nil?
        if msg.is_a?(String)
          hash = OpenSSL::Digest::SHA256.new
          hash << msg
          @digest = hash.digest
        else
          fail InvalidDigestError.new "a digest is required"
        end
      elsif digest.length == 32
        @digest = digest
      elsif digest.length == 64
        if digest !~ /\A[a-fA-F0-9]{64}\z/
          fail InvalidDigestError.new "digest must be a valid SHA-256 value"
        end
        @digest = [digest].pack("H*")
      else
        fail InvalidDigestError.new "digest must be a valid SHA-256 value"
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
        piece = "%02x" % x
        dir = Dir.new(dirname(piece))
        json_opts = {create_additions: false, symbolize_names: true}

        # TODO: validate the SHA-256 value.
        files = dir.each.sort.select { |file| /\A[0-9a-f]{62}\z/ =~ file }
        files.each do |component|
          file = "#{dir.path}/#{component}"
          metadata = JSON.load(File.new("#{file}.meta"), nil, json_opts)
          m = Message.new File.new(file), metadata, "#{piece}#{component}"
          @messages << m
          yield m
        end
      end
    end

    def save_metadata
      return unless @messages

      @messages.each do |m|
        f = File.new("#{filename(m)}.meta", "w")
        JSON.dump(m.metadata, f)
      end
    end
  end
end
