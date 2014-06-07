require 'ipaddr'

module Extruder
  module Processor
    class NetmaskProcessor
      def self.type
        :processor
      end

      # Group messages by the IP address ranges their origin server falls into.
      # Only consider /16s and smaller, since we aren't interested in blocking
      # the entire Internet.
      def postprocess(msgs, _results)
        groups = {}
        msgs.each do |m|
          os = m.metadata[:originserver]

          next if os.nil? || os[:address].nil?

          address = IPAddr.new os[:address]
          range = address.ipv4? ? 16..32 : 48..128
          range.each do |mask|
            groups[address.mask(mask)] ||= []
            groups[address.mask(mask)] << m.digest_as_hex
          end
        end

        { address_ranges: groups }
      end
    end

    ProcessorRegistry.instance.register(NetmaskProcessor, "netmask")
  end
end

