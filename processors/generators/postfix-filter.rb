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
          cidr = "#{address}/#{prefix}"
          puts "#{cidr}\t\tREJECT #{@reject_reason} (#{cidr})"
        end

        nil
      end

      protected
      # Computes the minimal set of ranges based on a hash of ranges to
      # collections of items.
      #
      # The algorithm is to sort the ranges into the smallest ranges first, then
      # for each range in that set:
      #
      #   * If another range we've already seen subsumes it, do nothing.
      #   * Otherwise, if this range subsumes one we've already seen and this
      #     one has more items than the other one, remove the other one and add
      #     this one.
      #   * Otherwise, if this range subsumes one we've already seen and it has
      #     the same number of items, do nothing.
      #   * Otherwise, this is a unique range, and we should add it one.
      #
      # @param range_map [Hash] map of IPAddr ranges to a collection with #size
      # @returns [Set] a minimal set of ranges
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

