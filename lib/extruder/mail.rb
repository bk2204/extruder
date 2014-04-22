require 'mail'

module Extruder
  class Message
    attr_accessor :metadata, :digest
    attr_writer :message

    def initialize(msg, metadata, digest = nil)
      @message = msg
      @metadata = metadata
      set_digest(msg, digest)
    end

    def digest_as_hex
      @digest.unpack('H*')[0]
    end

    def message
      if @message.is_a?(String)
        @message = Mail.read_from_string(@message)
      elsif @message.is_a?(Mail::Message)
        @message
      elsif @message.respond_to? :read
        @message = Mail.read_from_string(@message.read)
      end
    end

    private
    def set_digest(msg, digest)
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
        if digest !~ /\A[a-fA-F0-9]{64}\z/
          raise InvalidDigestError.new "digest must be a valid SHA-256 value"
        end
        @digest = [digest].pack("H*")
      else
        raise InvalidDigestError.new "digest must be a valid SHA-256 value"
      end
    end
  end

  class Store
    include Enumerable

    def each
      if !@messages.nil?
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
