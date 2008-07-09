#!/usr/bin/ruby
#
# Simple test

require 'rubbyt'

r = Rubbyt::AMQPConnection.new('127.0.0.1')
p r

p r.connect

