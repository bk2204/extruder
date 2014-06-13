#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'extruder/mail'
require 'processors/netmask'

message = <<EOM
From: alice@nonexistent.tld
To: bob@nonexistent.tld

Message
EOM

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

  it "can extract an IPv4 address from message metadata" do
    ip = "192.168.2.1"
    metadata = { originserver: { address: ip } }
    m = Extruder::Message.new(message, metadata)
    p = Extruder::Processor::NetmaskProcessor.new
    ranges = (16..32).map { |mask| IPAddr.new(ip).mask(mask) }
    expected = { address_ranges: {} }
    ranges.each { |r| expected[:address_ranges][r] = [m.digest_as_hex] }
    expect(p.postprocess([m], nil)).to eq expected
  end

  it "can extract an IPv4 address from message metadata" do
    ip = "fe80::15"
    metadata = { originserver: { address: ip } }
    m = Extruder::Message.new(message, metadata)
    p = Extruder::Processor::NetmaskProcessor.new
    ranges = (48..128).map { |mask| IPAddr.new(ip).mask(mask) }
    expected = { address_ranges: {} }
    ranges.each { |r| expected[:address_ranges][r] = [m.digest_as_hex] }
    expect(p.postprocess([m], nil)).to eq expected
  end
end
