require 'set'

class IPAddr
  attr_reader :mask_addr
end

module Extruder
  module Generator
    class PostfixFilterProcessor
      def initialize(params)
        @netmask_threshold = params["netmask_threshold"]
        @reject_reason = params["reject_reason"]
      end

      def postprocess(msgs, results)
        ranges = Set.new results[:address_ranges].select { |k, v|
          k.ipv4? && v.size >= @netmask_threshold
        }.keys

        minimized = Set.new
        ranges.each do |r|
          ignore = false
          minimized.each do |s|
            if s.include? r
              ignore = true
              break
            elsif r.include? s
              minimized.remove(s)
            end
          end
          minimized << r unless ignore
        end

        minimized.sort.each do |r|
          address = r.to_s
          invmask = (~r.mask_addr & 0xffffffff) + 1
          prefix = Math.log2(invmask).to_i
          puts "#{address}/#{prefix}\tREJECT #{@reject_reason}"
        end

        nil
      end
    end
  end
end

