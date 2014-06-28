#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'processors/netmask'

module Extruder
  class QueueRunner
    attr_reader :processors
  end
end

describe Extruder::QueueRunner do
  before(:all) do
    @proc_location = File.join(File.dirname(__FILE__), '..')
    text = <<EOM
---
locations:
  queue: /nonexistent
  processors:
    - #{@proc_location}
processors:
  -
    name: netmask
EOM
    @stringio = StringIO.new(text)
    @config = Extruder::Config.new(@stringio)
  end

  it 'can load processors from disk' do
    Extruder::QueueRunner.new(@config)
    x1 = Extruder::ProcessorRegistry.instance
    to_include = nil
    expect {
      to_include = [["netmask", Extruder::Processor::NetmaskProcessor]]
    }.not_to raise_error
    expect(x1).to include(*to_include)
  end
end
