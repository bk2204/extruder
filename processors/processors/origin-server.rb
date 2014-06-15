module Extruder
  module Processor

    # Process the received headers to determine the origin server.
    #
    # The origin server is the first one that is not internal and does not match
    # any of the exclude patterns.  A server is matched by its RDNS entry, or
    # its IP address if no RDNS entry is present.
    class OriginServerProcessor
      def self.type
        :processor
      end

      # Create a new processor.
      #
      # @param patterns [Enumerable] a set of regular expressions indicating
      #   servers to ignore
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

          return hop if !hop[:internal] && valid_target?(hostname)
        end

        nil
      end

      def valid_target?(server)
        @patterns.none? { |pat| pat =~ server }
      end
    end

    ProcessorRegistry.instance.register(OriginServerProcessor, 'origin-server')
  end
end
