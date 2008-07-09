#!/usr/bin/ruby
#
# Simple test

require 'rubbyt'

r = Rubbyt::AMQPConnection.new('127.0.0.1')
puts "#{r.inspect}\n\n"

p r.connect

