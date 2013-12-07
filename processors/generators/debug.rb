module Extruder
  module Generator
    class DebugProcessor
      def process(msg)
        puts [msg.digest_as_hex, msg.metadata].inspect
      end
    end
  end
end
