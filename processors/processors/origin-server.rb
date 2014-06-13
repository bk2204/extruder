module Extruder
  module Processor
    class OriginServerProcessor
      def self.type
        :processor
      end

      def initialize(patterns = [])
        @patterns = patterns.map { |pat| Regexp.compile(pat) }
      end

      def process(msg)
        origin = find_origin(msg.metadata[:received])
        msg.metadata[:originserver] = origin ? origin.dup : nil
      end

      private
      def find_origin(hops)
        hops.each do |hop|
          hostname = hop[:rdns] || hop[:address]

          next unless hostname

          return hop if !hop[:internal] && is_valid_target(hostname)
        end

        nil
      end

      def is_valid_target(server)
        @patterns.none? { |pat| pat =~ server }
      end
    end

    ProcessorRegistry.instance.register(OriginServerProcessor, 'origin-server')
  end
end
