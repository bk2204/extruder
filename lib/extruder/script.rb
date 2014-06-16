module Extruder
  # A collection of useful functions used by multiple scripts.
  module Script
    module_function

    def process_items(options, type)
      split_on = options.delete(:split_on)
      config = Extruder::Config.new options[:config], options

      if type == 'queue'
        return [config, Extruder::Queue.new(config.location(:queue))]
      end

      files = type == 'file' ? $stdin.read.split(split_on) : ARGV
      [config, files.map { |f| Extruder::Message.new File.open(f), {} }]
    end
  end
end
