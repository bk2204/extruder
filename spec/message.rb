#!/usr/bin/ruby
# encoding: UTF-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'mail'
require 'tempfile'

require 'extruder'
require 'extruder/mail'

describe Extruder::Message do
  before(:all) do
    @message = <<EOM
From: <john.fulano@example.com>
To: <mary.fulano@example.net>

Have a nice day!
EOM
    hash = OpenSSL::Digest::SHA256.new
    hash << @message
    @digest = hash.digest
    @parsed = Mail.read_from_string(@message)
    @hex_digest = @digest.unpack("H*")[0]
  end

  it 'should be able to be initialized with a string' do
    expect {
      Extruder::Message.new(@message, {tags: %w(a b c)})
    }.not_to raise_error
  end

  it 'should compute the digest automatically when initialized with a string' do
    m = Extruder::Message.new(@message, {tags: %w(a b c)})
    expect(m.digest).to eq @digest
    expect(m.digest_as_hex).to eq @hex_digest
  end

  it 'should raise an exception when digest is missing' do
    expect {
      Extruder::Message.new(@parsed, {tags: %w(a b c)})
    }.to raise_error Extruder::InvalidDigestError
  end

  it 'should accept a 32-byte digest' do
    m = nil
    expect {
      m = Extruder::Message.new(@parsed, {}, @digest)
    }.not_to raise_error
    expect(m.digest).to eq @digest
    expect(m.digest_as_hex).to eq @hex_digest
  end

  it 'should accept a 64-character digest' do
    m = nil
    expect {
      m = Extruder::Message.new(@parsed, {}, @hex_digest)
    }.not_to raise_error
    expect(m.digest).to eq @digest
    expect(m.digest_as_hex).to eq @hex_digest
  end

  it 'should return a message when passed a string' do
    m = Extruder::Message.new(@message, {}, @hex_digest)
    expect(m.message).to be_a Mail::Message
  end

  it 'should return a message when passed a message' do
    m = Extruder::Message.new(@parsed, {}, @hex_digest)
    expect(m.message).to be_a Mail::Message
  end

  it 'should return a message when passed an IO object' do
    io = StringIO.new(@message)
    m = Extruder::Message.new(io, {}, @hex_digest)
    expect(m.message).to be_a Mail::Message
  end
end
