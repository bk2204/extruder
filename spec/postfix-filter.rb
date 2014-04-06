#!/usr/bin/ruby
# encoding: UTF-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'generators/postfix-filter'

describe Extruder::Generator::PostfixFilterProcessor do
  it "has the correct type" do
    expect(Extruder::Generator::PostfixFilterProcessor.type).to eq :generator
  end

  it "can postprocess" do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    expect(p).to respond_to(:postprocess).with(2).arguments
  end

  it "cannot process" do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    expect(p).not_to respond_to(:process)
  end

  it "can compute CIDR notation correctly" do
    p = Extruder::Generator::PostfixFilterProcessor.new({})
    (0..32).each do |n|
      x = (0xffffffff << n) & 0xffffffff
      expect(p.send(:compute_prefix, x)).to eq (32 - n)
    end
  end

  it "can compute a set of minimal IPv4 ranges" do
    p = Extruder::Generator::PostfixFilterProcessor.new({ "netmask_threshold" => 1})
    range_map = {}
    [
      "192.168.2.1/32",
      "192.168.2.254/32",
      "192.168.2.128/25",
    ].each do |r|
      range_map[IPAddr.new(r)] = [1, 2]
    end
    range_map[IPAddr.new("192.168.2.0/24")] = [1, 2, 3, 4, 5, 6]
    result = Set.new([IPAddr.new("192.168.2.0/24")])
    expect(p.send(:compute_minimal_ranges, range_map)).to eq result
  end
end
