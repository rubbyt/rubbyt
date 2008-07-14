#
# Rubbyt - Ruby implementation of AMQP client for RabbitMQ
#

module Rubbyt
  # Constants
  DEFAULT_USER = "guest".freeze
  DEFAULT_PASS = "guest".freeze
  DEFAULT_VHOST = "/".freeze
  DEFAULT_AMQP_PORT = 5672
  AMQP_PROTO_HEADER = "AMQP".freeze
  AMQP_FRAME_END = 206
  DEFAULT_AMQP_MAJOR_VERSION = 8
  DEFAULT_AMQP_MINOR_VERSION = 0
  AMQPLAIN = "AMQPLAIN".freeze

  # Exceptions
  class Exception < ::Exception; end
  class AMQPRedirect < Exception; end
  class AMQPIncompleteFrame < Exception; end
  class BufferOverflow < Exception; end
  class BrokerCompatError < Exception; end
end

require 'rubbyt/frame'
require 'rubbyt/message'
require 'rubbyt/client'

