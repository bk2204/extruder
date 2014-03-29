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
        @config.location(:processors).each do |l|
          ["processors", "parsers", "generators"].each do |d|
            dirname = File.join(l, "processors", d)
            Dir.foreach(dirname) do |f|
              next if f.start_with?(".")
              next unless f.end_with?(".rb")

              load File.join(dirname, f)
            end
          end
        end

        @processors = @config.processors.map do |x|
          klass = ProcessorRegistry.instance.lookup(x[:name])
          klass.new(*x[:args])
        end
      end
  end
end
