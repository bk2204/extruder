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
        minimized = compute_minimal_ranges(results[:address_ranges])

        minimized.sort.each do |r|
          address = r.to_s
          invmask = (~r.mask_addr & 0xffffffff) + 1
          prefix = 32 - Math.log2(invmask).to_i
          puts "#{address}/#{prefix}\t\tREJECT #{@reject_reason}"
        end

        nil
      end

      protected
      def compute_minimal_ranges(range_map)
        ranges = Set.new range_map.select { |k, v|
          k.ipv4? && v.size >= @netmask_threshold
        }.keys

        minimized = Set.new
        ranges.to_a.sort { |a, b| b.mask_addr <=> a.mask_addr }.each do |r|
          ignore = false
          minimized.each do |s|
            if s.include?(r)
              ignore = true
              break
            elsif r.include?(s)
              if range_map[r].size > range_map[s].size
                minimized.delete(s)
              else
                ignore = true
              end
            end
          end
          minimized << r unless ignore
        end

        minimized
      end
    end
  end
end

