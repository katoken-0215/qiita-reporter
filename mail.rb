#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'net/smtp'

MAIL_SUBJECT = ENV['MAIL_SUBJECT']
MAIL_FROM = ENV['MAIL_FROM']
MAIL_TO = ENV['MAIL_TO']
SMTP_SERVER = ENV['SMTP_SERVER']

header = <<-"EOS"
From: Qiita Bot <#{ MAIL_FROM }>
To: #{ MAIL_TO }
Subject: #{ MAIL_SUBJECT }
Content-Type: text/html; charset=UTF-8
EOS

body = STDIN.read

Net::SMTP.start(SMTP_SERVER, 25) do |smtp|
  smtp.send_message(header + body, MAIL_FROM, MAIL_TO.split(','))
end
