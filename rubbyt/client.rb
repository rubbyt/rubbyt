
require 'rubbyt/net'

module Rubbyt

class AMQPConnection

  attr_reader :host, :port, :user, :pass, :vhost
  attr_reader :socket, :send_buffer, :recv_buffer
  attr_writer :last_recv, :last_send, :last_broker_heartbeat

  include NonBlockingSocket

  def initialize(host, opts={})
    @host = host
    @port = opts[:port] || DEFAULT_AMQP_PORT
    @user = opts[:user] || DEFAULT_USER
    @pass = opts[:pass] || opts[:password] || DEFAULT_PASS
    @vhost = opts[:vhost] || DEFAULT_VHOST

    @socket = nil
    @send_buffer = ""
    @recv_buffer = ""

    @last_recv = nil
    @last_send = nil
    @last_broker_heartbeat = nil
  end

  def connect
    socket_connect
    establish_amqp_connection
  end

  def last_activity
    last_recv > last_send ? last_recv : last_send
  end

  #
  # Mid-level AMQP methods
  #
  def find_or_create_channel
  end

  def establish_amqp_connection
    amqp_send_protocol_header
    amqp_recv_start
    amqp_send_start_ok
    amqp_recv_tune
    amqp_send_tune_ok
    amqp_send_open
    amqp_recv_open_ok
    puts "established"
    self
  end

  def amqp_send_protocol_header
    # AMQP<1><1><spec major as octet><spec minor as octet>
    # this is the only time when we send non-method frame?
    send_buffer << AMQP_PROTO_HEADER << 
      [1, 1, DEFAULT_AMQP_MAJOR_VERSION,
        DEFAULT_AMQP_MINOR_VERSION].pack("CCCC")
    send(blocking=true)
  end

  def amqp_recv_start
    m = recv(blocking=true)
    p m
    raise "inside amqp_recv_start NOTIMPL FIXME"
  end

  def amqp_send_start_ok
  end

  def amqp_recv_tune
  end

  def amqp_send_tune_ok
  end

  def amqp_send_open
  end

  def amqp_recv_open_ok
  end

  #
  # High level methods
  #
  def publish
  end

  def create_consumer
  end

  def consumer_loop
  end



end
end


