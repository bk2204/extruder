module Extruder
  module Generator
    class DebugProcessor
      def self.type
        :generator
      end

      def process(msg)
        puts [msg.digest_as_hex, msg.metadata].inspect
      end

      def postprocess(msgs, results)
        puts results.inspect
      end
    end

    ProcessorRegistry.instance.register(DebugProcessor, "debug")
  end
end
