
require 'rubbyt/net'

module Rubbyt

class AMQPConnection

  attr_reader :host, :port, :user, :pass, :vhost
  attr_reader :socket, :send_buffer, :recv_buffer, :frame_buffer
  attr_writer :last_recv, :last_send, :last_broker_heartbeat
  attr_reader :server_properties

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
    @frame_buffer = Array.new   # array of queued outgoing frames

    @last_recv = nil
    @last_send = nil
    # @last_broker_heartbeat = nil   # not used for now

    @client_properties = { :platform => "Ruby",
            :product => "Rubbyt",
            :information => "http://github.com/rubbyt/rubbyt",
            :version => "0.0",
            :copyright => "FIXME" }
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
    process_amqp_connection_start
    process_amqp_connection_tune
    process_amqp_connection_open
    puts "established"
    self
  end

  def amqp_send_protocol_header
    # AMQP<1><1><spec major as octet><spec minor as octet>
    # this is the only time when we send non-method frame?
    send_buffer << AMQP_PROTO_HEADER << 
      [1, 1, DEFAULT_AMQP_MAJOR_VERSION,
        DEFAULT_AMQP_MINOR_VERSION].pack("C4")
    send(blocking=true)
  end

  def process_amqp_connection_start
    m = recv(blocking=true)
    @server_properties = m.server_properties

    # make sure it is a start method
    raise(ProtocolError,:unexpected_method) unless
                m.method_name == :start && m.class_name == :connection
    # make sure broker supports AMQPLAIN
    raise(BrokerCompatError,:broker_does_not_support_amqplain) unless
                m.mechanisms.split.include?(AMQPLAIN)
    # make sure major/minor are 8/0
    raise(BrokerCompatError,:major_minor_version_mismatch) unless
                m.version_major == 8 && m.version_minor == 0

    # send start-ok
    m1 = AMQPMethod.create(:connection, :start_ok)
    m1.mechanism = AMQPLAIN
    m1.response = { :LOGIN => @user, :PASSWORD => @pass }
    m1.locale = DEFAULT_AMQP_LOCALE
    m1.client_properties = @client_properties
    @frame_buffer << m1
    send(blocking=true)
  end

  def process_amqp_connection_tune
    m = recv(blocking=true)

    raise(ProtocolError,:unexpected_method) unless
                m.method_name == :tune && m.class_name == :connection
    
    # send tune-ok
    m1 = AMQPMethod.create(:connection, :tune_ok)

    # FIXME TODO
    # put more thought into it
    # for now, we will just take whatever broker gives us
    # in case of heartbeat, we don't want it for now
    @channel_max = m.channel_max
    @heartbeat = 0
    @frame_max = m.frame_max
    m1.channel_max = @channel_max
    m1.heartbeat = @heartbeat
    m1.frame_max = @frame_max
    @frame_buffer << m1
    send(blocking=true)
  end

  def process_amqp_connection_open
    p "FIXME TODO NOTIMPL"
    exit
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


