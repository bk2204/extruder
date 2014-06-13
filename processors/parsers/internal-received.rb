require 'parsers/received'

module Extruder
  module Parser
    # Process a variety of internal received headers.  Simply indicate these
    # with a single :internal symbol.
    class InternalReceivedProcessor < ReceivedProcessor
      def process(msg)
        initialize_metadata(msg)
        each_received(msg) do |header|
          header = header.to_s

          if header =~ /by\s(?<server>\S+)\s+
            via\slistexpand\s+
            id\s+(?<queueid>\S+)/x

            { internal: true }
          else
            nil
          end
        end
      end
    end

    ProcessorRegistry.instance.register(InternalReceivedProcessor,
                                        'internal-received')
  end
end
