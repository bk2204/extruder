#!/usr/bin/ruby
# encoding: UTF-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tmpdir'

require 'extruder'

class ExampleStore < Extruder::Store
  attr_reader :type

  def initialize(location)
    @location = location
    @type = 'queue'
  end
end

describe Extruder::Store do
  before(:all) do
    @tempdir = Dir.mktmpdir
  end

  after(:all) do
    FileUtils.remove_entry @tempdir
  end

  it 'should create a directory structure' do
    path = File.join(@tempdir, 'queue')
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
end
