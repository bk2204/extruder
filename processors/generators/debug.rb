module Extruder
  module Generator
    class DebugProcessor
      def process(msg)
        puts [msg.digest_as_hex, msg.metadata].inspect
      end

      def postprocess(msgs, results)
        puts results.inspect
      end
    end
  end
end
