require 'mail'

module Extruder
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

    def each
      require 'mail'

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
end