require 'parsers/received'

module Extruder
  module Parser
    class PostfixReceivedProcessor < ReceivedProcessor
      def process(msg)
        initialize_metadata(msg)
        each_received(msg) do |header|
          header = header.to_s

          if header =~ /from\s+
            (?<heloname>\S+)\s+
            \((?:(?<rdns>\S+)\s+)?
            \[(?:(?<protocol>IPv6):)?(?<address>[^\]]+)\]\)\s+
            (?:\(using\s(?<tlsprotocol>\S+)\swith\scipher\s(?<tlscipher>\S+)\s+
             \([^\)]+\)\))?.*?
            by\s(?<server>\S+)\s\(Postfix\)\s+
            with\s+(?<smtpprotocol>\S+)\s+
            id\s+(?<queueid>\S+)\s+
            (?:for\s+<(?<destaddress>[^>]+)>)?/x

            metadata = {}
            $~.names.each { |x| metadata[x.to_sym] = $~[x] }
            metadata[:protocol] ||= "IPv4"
            metadata
          else
            nil
          end
        end
      end
    end

    ProcessorRegistry.instance.register(PostfixReceivedProcessor,
                                        "postfix-received")
  end
end
