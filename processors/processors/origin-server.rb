module Extruder
  module Processor
    class OriginServerProcessor
      def self.type
        :processor
      end

      def initialize(patterns)
        @patterns = patterns.map { |pat| Regexp.compile(pat) }
      end

      def process(msg)
        meta = msg.metadata[:received]

        # The server, or false if it cannot be determined.
        origin = nil
        meta.each do |hop|
          hostname = hop[:rdns] || hop[:address]
          if origin.nil?
            if hostname && is_valid_target(hostname)
              origin = hop
            elsif !hop[:internal]
              origin = false
            end
          end
        end

        msg.metadata[:originserver] = origin ? origin.dup : nil
      end

      private
      def is_valid_target(server)
        @patterns.none? { |pat| pat =~ server }
      end
    end

    ProcessorRegistry.instance.register(OriginServerProcessor, 'origin-server')
  end
end
