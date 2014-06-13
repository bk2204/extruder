#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'processors/netmask'

class DummyClass
end

describe Extruder::ProcessorRegistry do
  it "is a Singleton" do
    x1 = Extruder::ProcessorRegistry.instance
    x2 = Extruder::ProcessorRegistry.instance
    expect(x1).to be_a Singleton
    expect(x1.object_id).to eq x2.object_id
  end

  it "is an Enumerable" do
    inst = Extruder::ProcessorRegistry.instance
    expect(inst).to be_an Enumerable
    expect(inst).to respond_to :each
  end

  it "should be able to register and lookup processors" do
    inst = Extruder::ProcessorRegistry.instance
    inst.register(DummyClass, :dummy_class)
    expect(inst.lookup(:dummy_class)).to eq DummyClass
    expect(inst).to include [:dummy_class, DummyClass]
  end

  it "should have registered processors automatically" do
    inst = Extruder::ProcessorRegistry.instance
    result = inst.find { |(_, v)| v == Extruder::Processor::NetmaskProcessor }
    expect(result).to_not be nil
  end
end
