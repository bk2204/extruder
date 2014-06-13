#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'extruder/mail'
require 'processors/origin-server'

describe Extruder::Processor::OriginServerProcessor do
  it 'has the correct type' do
    expect(Extruder::Processor::OriginServerProcessor.type).to eq :processor
  end

  it 'can process' do
    p = Extruder::Processor::OriginServerProcessor.new []
    expect(p).to respond_to(:process).with(1).arguments
  end

  it 'cannot postprocess' do
    p = Extruder::Processor::OriginServerProcessor.new []
    expect(p).not_to respond_to(:postprocess)
  end

  it 'compiles correct patterns successfully' do
    patterns = [
      'google\.com',
      '^internal\.',
      '\.localdomain$'
    ]
    expect { Extruder::Processor::OriginServerProcessor.new patterns }
      .not_to raise_error
  end

  it 'raises an exception on invalid patterns' do
    patterns = [
      '*google\.com',
      '^in(ternal\.',
      '\.localdomain$?'
    ]
    expect { Extruder::Processor::OriginServerProcessor.new patterns }
      .to raise_error(RegexpError)
  end

  it 'finds the first hop by default' do
    metadata = {
      received: [
        { rdns: 'abc.com' },
        { rdns: 'def.com' },
        { rdns: 'ghi.org' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new([]).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][0]
  end

  it 'finds the first matching hop' do
    metadata = {
      received: [
        { rdns: 'abc.com' },
        { rdns: 'def.net' },
        { rdns: 'ghi.org' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new(['\.com$']).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][1]
  end

  it 'finds the first matching non-internal hop' do
    metadata = {
      received: [
        { rdns: 'abc.com' },
        { rdns: 'def.net', internal: true },
        { rdns: 'ghi.org' },
        { rdns: 'jkl.gov' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new(['\.com$']).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][2]
  end

  it 'falls back to address if no rdns is found' do
    metadata = {
      received: [
        { address: '127.0.0.1' },
        { rdns: 'def.net', internal: true },
        { rdns: 'ghi.org' },
        { rdns: 'jkl.gov' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new([]).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][0]
  end

  it 'checks addresses against the patterns' do
    metadata = {
      received: [
        { address: '127.0.0.1' },
        { rdns: 'def.net', internal: true },
        { rdns: 'ghi.org' },
        { rdns: 'jkl.gov' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new(['^127\.']).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][2]
  end

  it 'ignores hops with no rdns or address' do
    metadata = {
      received: [
        { rand: 'abc.com' },
        { rdns: 'def.net', internal: true },
        { rdns: 'ghi.org' },
        { rdns: 'jkl.gov' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new([]).process(msg)
    expect(metadata[:originserver]).to eq metadata[:received][2]
  end

  it 'sets the value to nil if no valid hop is found' do
    metadata = {
      received: [
        { rdns: 'abc.com' },
        { rdns: 'def.com' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new(['\.com$']).process(msg)
    expect(metadata).to include :originserver
    expect(metadata[:originserver]).to eq nil
  end

  it 'dups the appropriate received entry' do
    metadata = {
      received: [
        { rdns: 'abc.com' }
      ]
    }
    msg = double(Extruder::Message, metadata: metadata)
    Extruder::Processor::OriginServerProcessor.new([]).process(msg)
    expected = metadata[:received][0]
    expect(metadata[:originserver]).to eq expected
    expect(metadata[:originserver].object_id).to_not eq expected.object_id
  end
end
