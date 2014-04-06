#!/usr/bin/ruby
# encoding: UTF-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'processors/netmask'

describe Extruder::Processor::NetmaskProcessor do
  it "has the correct type" do
    expect(Extruder::Processor::NetmaskProcessor.type).to eq :processor
  end

  it "can postprocess" do
    p = Extruder::Processor::NetmaskProcessor.new
    expect(p).to respond_to(:postprocess).with(2).arguments
  end

  it "cannot process" do
    p = Extruder::Processor::NetmaskProcessor.new
    expect(p).not_to respond_to(:process)
  end
end
