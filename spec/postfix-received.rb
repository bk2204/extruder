#!/usr/bin/ruby
# encoding: UTF-8

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'processors')

require 'extruder'
require 'extruder/mail'
require 'parsers/postfix-received'

message = <<EOM
From: alice@nonexistent.tld
To: bob@nonexistent.tld
Received: from mx1.example.tld (mail.example.tld [198.51.100.10])
        (using TLSv1 with cipher DHE-RSA-AES256-SHA (256/256 bits))
        (No client certificate requested)
        by mx1.sample.tld (Postfix) with ESMTPS id 65C4B2808E
        for <user@sample.tld>; Wed, 18 Jun 2014 16:55:10 +0000 (UTC)

Message
EOM

describe Extruder::Parser::PostfixReceivedProcessor do
  it 'has the correct type' do
    expect(Extruder::Parser::PostfixReceivedProcessor.type).to eq :parser
  end

  it 'can process' do
    p = Extruder::Parser::PostfixReceivedProcessor.new
    expect(p).to respond_to(:process).with(1).arguments
  end

  it 'cannot postprocess' do
    p = Extruder::Parser::PostfixReceivedProcessor.new
    expect(p).not_to respond_to(:postprocess)
  end

  it 'can parse a basic Postfix header' do
    metadata = {}
    expected = {
      received: [
        {
          heloname: 'mx1.example.tld',
          rdns: 'mail.example.tld',
          protocol: 'IPv4',
          address: '198.51.100.10',
          tlsprotocol: 'TLSv1',
          tlscipher: 'DHE-RSA-AES256-SHA',
          server: 'mx1.sample.tld',
          smtpprotocol: 'ESMTPS',
          queueid: '65C4B2808E',
          destaddress: 'user@sample.tld',
          date: 'Wed, 18 Jun 2014 16:55:10 +0000'
        }
      ]
    }
    m = Extruder::Message.new(message, metadata)
    p = Extruder::Parser::PostfixReceivedProcessor.new
    p.process(m)
    expect(metadata).to eq expected
  end
end
