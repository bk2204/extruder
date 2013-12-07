module Extruder
  module Parser
    class PostfixReceivedProcessor
      def process(msg, metadata)
        first = extract_first(msg).to_s
        if first =~ /from\s+
          (?<heloname>\S+)\s+
          \((?:(?<rdns>\S+)\s+)?
          \[(?:(?<protocol>IPv6):)?(?<address>[^\]]+)\]\)\s+
          (?:\(using\s(?<tlsprotocol>\S+)\swith\scipher\s(?<tlscipher>\S+)\s+
           \([^\)]+\)\))?.*?
          by\s(?<server>\S+)\s\(Postfix\)\s+
          with\s+(?<smtpprotocol>\S+)\s+
          id\s+(?<queueid>\S+)\s+
          for\s+<(?<destaddress>[^>]+)>/x

          metadata[:received] = {}
          $~.names.each { |x| metadata[:received][x.to_sym] = $~[x] }
          metadata[:received][:protocol] ||= "IPv4"
        end

        metadata
      end

      private
      def extract_first(msg)
        received = msg.received
        if received.is_a?(Array)
          received[0]
        else
          received
        end
      end
    end
  end
end
