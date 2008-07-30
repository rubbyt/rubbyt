
module Rubbyt

AMQPMethod.new(10, 10, :connection, :start) do |m|
  m.field :version_major, :octet
  m.field :version_minor, :octet
  m.field :server_properties, :table
  m.field :mechanisms, :longstr
  m.field :locales, :longstr
end

AMQPMethod.new(10, 11, :connection, :start_ok) do |m|
  m.field :client_properties, :table
  m.field :mechanism, :shortstr
  m.field :response, :table     # for AMQPLAIN - LOGIN/PASSWORD table
  m.field :locale, :shortstr
end

# skip secure for now

AMQPMethod.new(10, 30, :connection, :tune) do |m|
  m.field :channel_max, :short
  m.field :frame_max, :long
  m.field :heartbeat, :short
end

AMQPMethod.new(10, 31, :connection, :tune_ok) do |m|
  m.field :channel_max, :short
  m.field :frame_max, :long
  m.field :heartbeat, :short
end

AMQPMethod.new(10, 40, :connection, :open) do |m|
  m.field :virtual_host, :shortstr
  m.field :capabilities, :shortstr
  m.field :insist, :bit
end

AMQPMethod.new(10, 41, :connection, :open_ok) do |m|
  m.field :known_hosts, :shortstr
end

AMQPMethod.new(10, 50, :connection, :redirect) do |m|
  m.field :host, :shortstr
  m.field :known_hosts, :shortstr
end

AMQPMethod.new(10, 60, :connection, :close) do |m|
  m.field :reply_code, :short
  m.field :reply_text, :shortstr
  m.field :class_id, :short
  m.field :method_id, :short
end

AMQPMethod.new(10, 61, :connection, :close_ok) do |m|
end

end

