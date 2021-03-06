#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'generators/postfix-filter'

module Extruder
  module Generator
    class PostfixFilterProcessor
      attr_accessor :output

      def puts(*args)
        @output ||= []
        @output << args
      end
    end
  end
end

describe Extruder::Generator::PostfixFilterProcessor do
  it 'has the correct type' do
    expect(Extruder::Generator::PostfixFilterProcessor.type).to eq :generator
  end

  it 'can postprocess' do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    expect(p).to respond_to(:postprocess).with(2).arguments
  end

  it 'cannot process' do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    expect(p).not_to respond_to(:process)
  end

  it 'can compute CIDR notation correctly' do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    (0..32).each do |n|
      x = (0xffffffff << n) & 0xffffffff
      prefix = 32 - n
      expect(p.send(:compute_prefix, x)).to eq prefix
    end
  end

  it 'can compute a set of minimal IPv4 ranges' do
    p = Extruder::Generator::PostfixFilterProcessor.new('netmask_threshold' => 1)
    range_map = {}
    [
      '192.168.2.1/32',
      '192.168.2.254/32',
      '192.168.2.128/25',
    ].each do |r|
      range_map[IPAddr.new(r)] = [1, 2]
    end
    range_map[IPAddr.new('192.168.2.0/24')] = [1, 2, 3, 4, 5, 6]
    result = Set.new([IPAddr.new('192.168.2.0/24')])
    expect(p.send(:compute_minimal_ranges, range_map)).to eq result
  end

  it 'does not promote below the threshold when not aggressive' do
    p = Extruder::Generator::PostfixFilterProcessor.new('netmask_threshold' => 3)
    range_map = {
      IPAddr.new('192.168.2.1/32') => [1, 2, 3],
      IPAddr.new('192.168.2.254/32') => [4],
      IPAddr.new('192.168.2.128/25') => [5],
    }
    range_map[IPAddr.new('192.168.2.0/24')] = [1, 2, 3, 4, 5]
    result = Set.new([IPAddr.new('192.168.2.1/32')])
    expect(p.send(:compute_minimal_ranges, range_map)).to eq result
  end

  it 'promotes below the threshold when aggressive' do
    p = Extruder::Generator::PostfixFilterProcessor.new('netmask_threshold' => 3, 'aggressive' => true)
    range_map = {
      IPAddr.new('192.168.2.1/32') => [1, 2, 3],
      IPAddr.new('192.168.2.254/32') => [4],
      IPAddr.new('192.168.2.128/25') => [5],
    }
    range_map[IPAddr.new('192.168.2.0/24')] = [1, 2, 3, 4, 5]
    result = Set.new([IPAddr.new('192.168.2.0/24')])
    expect(p.send(:compute_minimal_ranges, range_map)).to eq result
  end

  it 'produces properly formatted output' do
    ranges = ['192.168.2.1/32', '192.168.3.1/32', '192.168.4.128/25']
    metadata = {address_ranges: {}}
    ranges.each { |r| metadata[:address_ranges][IPAddr.new(r)] = [1, 2, 3] }
    reason = 'junk'
    p = Extruder::Generator::PostfixFilterProcessor.new('netmask_threshold' => 1, 'reject_reason' => reason)
    p.postprocess([], metadata)
    ranges.zip(p.output.flatten).each do |(r, line)|
      expect(line).to match(/\A#{r}\s+REJECT\s+#{reason}\s+\(#{r}\)/)
    end
  end
end
