module Extruder
  module Parser
    class ReceivedProcessor
      def self.type
        :parser
      end

      def initialize_metadata(msg)
        if !msg.metadata.key?(:received)
          msg.metadata[:received] = []
          message_count(msg).times { |i| msg.metadata[:received] << {} }
        end
      end

      # Processes each received header.
      #
      # Takes a block with a single argument, the received header.  That block
      # should return a hash with metadata if the processor could extract it,
      # nil otherwise.
      def each_received(msg)
        received = msg.message.received
        if received.is_a?(Array)
          received.each_index do |i|
            update_metadata(msg, i, yield(received[i]))
          end
        else
          update_metadata(msg, 0, yield(received))
        end
      end

      private
      def update_metadata(msg, i, metadata)
        if !metadata.nil?
          msg.metadata[:received][i] = metadata
        end
      end

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
