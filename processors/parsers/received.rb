module Extruder
  module Parser
    class ReceivedProcessor
      def initialize_metadata(msg)
        if !msg.metadata.key?(:received)
          msg.metadata[:received] = []
          message_count(msg).times { |i| msg.metadata[:received] << {} }
        end
      end

      def each_received(msg)
        received = msg.message.received
        if received.is_a?(Array)
          received.each_index { |i| yield received[i], msg.metadata[:received][i] }
        else
          yield received, msg.metadata[:received][0]
        end
      end

      private
      def message_count(msg)
        received = msg.message.received
        if received.is_a?(Array)
          received.length
        else
          1
        end
      end
    end
  end
end
