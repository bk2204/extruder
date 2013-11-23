require 'json'
require 'mail'

module Extruder
  class QueueRunner
    def initialize(config)
      @config = config

      load_processors
    end

    def process(items)
      items.each do |item|
        metadata = item[:metadata]
        @processors.each do |processor|
          metadata = processor.process(item[:message], metadata)
        end
      end
    end

    private
      def load_processors
        @processors = @config.processors.map do |x|
          require x[:require]
          klass = x[:name].split('::').inject(Object) { |o,c| o.const_get c }
          klass.new(*x[:args])
        end
      end
  end
end
