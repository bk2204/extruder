#!/usr/bin/ruby
# encoding: UTF-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tempfile'

require 'extruder'

describe Extruder::Config do
  before(:all) do
    @proc_location = File.join(File.dirname(__FILE__), '..', 'processors')
    @tempfile = Tempfile.new('config')
    @tempfile.print <<EOM
---
locations:
  queue: /nonexistent
  processors: #{@proc_location}
processors:
  -
    name: netmask
EOM
    @tempfile.flush
  end

  it 'should be able to load a YAML configuration file' do
    c = Extruder::Config.new(@tempfile.path)
    expect(c.location(:queue)).to eq '/nonexistent'
    expect(c.location(:processors)).to eq @proc_location
    expect(c.processors).to eq [{name: 'netmask'}]
  end
end
