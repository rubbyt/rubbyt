
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
  m.field :frame_max, :short
  m.field :heartbeat, :short
end

end

