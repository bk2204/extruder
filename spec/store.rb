#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'openssl'
require 'tmpdir'

require 'extruder'

class ExampleStore < Extruder::Store
  attr_reader :type

  def initialize(location)
    @location = location
    @type = 'queue'
  end
end

class TestMessage
  attr :digest_as_hex

  def initialize(digest)
    @digest_as_hex = digest
  end
end

describe Extruder::Store do
  before(:all) do
    @tempdir = Dir.mktmpdir
    @path = File.join(@tempdir, 'queue')
  end

  after(:all) do
    FileUtils.remove_entry @tempdir
  end

  it 'should create a directory structure' do
    path = @path
    s = ExampleStore.new path
    s.create
    [
      [[path, File.join(path, s.type)], 0755],
      [(0..255).map { |x| File.join(path, s.type, '%02x' % x)}, 01773],
      [[File.join(path, s.type, 'tmp')], 03733],
    ].each do |(files, mode)|
      umask = File.umask
      files.each do |file|
        st = File::stat(file)
        expect(st.mode & 07777).to eq mode & ~umask & 07777
        expect(st.directory?).to eq true
      end
    end
  end

  it 'should create a location based on a path and type' do
    s = ExampleStore.new @tempdir
    expect(s.send(:location)).to eq @path
  end

  it 'should create a directory name based on a digest' do
    digest = OpenSSL::Digest::SHA256.new.digest.unpack('H*')[0]
    s = ExampleStore.new @tempdir
    expect(s.send(:dirname, digest)).to eq File.join(@path, digest[0..1])
  end

  it 'should create a directory name based on a test message digest' do
    digest = OpenSSL::Digest::SHA256.new.digest.unpack('H*')[0]
    msg = TestMessage.new digest
    s = ExampleStore.new @tempdir
    expect(s.send(:dirname, msg)).to eq File.join(@path, digest[0..1])
  end

  it 'should create a filename based on a test message digest' do
    digest = OpenSSL::Digest::SHA256.new.digest.unpack('H*')[0]
    msg = TestMessage.new digest
    s = ExampleStore.new @tempdir
    expect(s.send(:filename, msg)).to eq File.join(@path, digest[0..1],
                                                   digest[2..-1])
  end
end
