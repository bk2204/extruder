require 'json'

module Extruder
  class QueueRunner
    def initialize(config)
      @config = config

      load_processors
    end

    def run(items)
      items = items.to_a
      process items
      postprocess items
    end

    def process(items)
      processors = @processors.each.select { |p| p.respond_to? :process }
      items.each do |item|
        processors.each do |processor|
          processor.process(item)
        end
      end
    end

    def postprocess(items)
      results = {}
      @processors.each do |processor|
        if processor.respond_to? :postprocess
          results.merge!(processor.postprocess(items, results) || {})
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
