
module Rubbyt

class AMQPMethod
  @@list = Array.new
  @@lookup = Hash.new
  class << self
    def build_from_frame(data, type, channel, size)
      class_id, method_id = data.read(:short, :short)
      m = AMQPMethod.create(class_id, method_id)
      m.update(:type => type, :channel => channel, :size => size)
      m.unpack(data)

      puts "\nBuilt AMQPMethod instance from frame:\n#{m.inspect}"
      return m
    end

    def find_all_by_class_id
      # FIXME
    end

    def find_all_by_class_name
      # FIXME
    end

    def create(class_id, method_id)
      # FIXME is this efficient?
      p @@list
      p class_id
      p method_id
      @@list[@@lookup[class_id][method_id]].clone
    end

    def call_attr_accessor(sym)
      attr_accessor(sym)
    end
      
  end

  attr_reader :fields, :field_names
  attr_accessor :type, :channel, :size

  def initialize(class_id, method_id, class_name, method_name, &block)
    @class_id = class_id
    @method_id = method_id
    @class_name = class_name
    @method_name = method_name
    @fields = Array.new
    @field_names = Array.new
    block.call(self)

    @@list << self
    @@lookup[class_id] ||= Hash.new
    @@lookup[class_id][method_id] = @@list.length - 1
  end

  # this method is here to pass data we got from frame inside into method
  # FIXME
  # need a better way
  # also, is frame type always 1?
  def update(opts)
    @type = opts[:type]
    @channel = opts[:channel]
    @size = opts[:size]
  end
    

  def field(name, type)
    @fields << [name, type]
    @field_names << name
    self.class.call_attr_accessor(name)
  end

  def unpack(s)
    fields.each do |fld|
      send("#{fld[0]}=", s.read(fld[1]))
    end
    self
  end

  def pack
    # FIXME
  end
    
end

# generate these from spec xml FIXME
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










String.class_eval do
  def rewind!
    @pos = 0
  end

  def read(*syms)
    res = Array.new
    @pos ||= 0
    syms.each do |sym|
      case sym
        when :octet
          res << _read("C", 1)
        when :short
          res << _read("n", 2)
        when :long
          res << _read("N", 4)
        when :longlong
          # FIXME
        when :shortstr
          len = read(:octet)
          res << slice(@pos, len)
          @pos += len
        when :longstr
          len = read(:long)
          res << slice(@pos, len)
          @pos += len
        when :timestamp
          res << read(:longlong)
        when :bit
          # FIXME
        when :table
          t = _read_table
          if res.is_a?(Array)
            res << t
          else
            res = t
          end
        else
          # FIXME remove
          p "String.read #{sym}"
          exit
      end # of case sym
    end
    raise BufferOverflow if @pos > length
    return syms.length == 1 ? res[0] : res
  end

  def write(sym, data)
    # FIXME
  end

  def eof?
    @pos ||= 0
    @pos == length
  end

  private

  def _read(unpack_spec, len)
    r = slice(@pos, len).unpack(unpack_spec).pop
    @pos += len
    return r
  end

  def _read_table
    # to a certain extent, based on pyamqplib
    table = Hash.new
    table_data = read(:longstr)

    while not table_data.eof?
      key = table_data.read(:shortstr)
      type = table_data.read(:octet)
      case type
        when 83: # 'S'
          val = table_data.read(:longstr)
#        when 'I'
#          val = table_data.read(:long) <-- FIXME
#        when 'D'
#          d = table_data.read(:octet)
#          val = table_data.read(:long) / (10 ** d) <-- FIXME
#        when 'T':
#          val = table_data.read(:timestamp) <-- FIXME
#        when 'F':
#          val = table_data.read(:table)
        else 
          # FIXME raise an exception instead of exit
          p "Unknown type in _read_table: #{type}"
          exit
      end
      table[key] = val
    end
    return table
  end

end


#class Method
#
#  def self.build_from_frame(data)
#    raise AMQPIncompleteFrame(:header) if data.length < 7
#    type, chan, size = data.read(:octet, :short, :long)
#    p "type #{type}"
#    p "channel #{chan}"
#    p "size #{size}"
#
#    raise AMQPIncompleteFrame(:payload) if data.length < size+8
#    raise AMQPIncompleteFrame(:frame_end) if data[size+7] != AMQP_FRAME_END
#
#    # Method.new(data[7..size+7], type, chan, size)
#    class_id, method_id = data.read(:short, :short)
#    m = AMQPMethod.find(class_id, method_id).clone
#    m.unpack(data)
#
#    exit    # FIXME NOTIMPL
#  end
#
#  def initialize(data, type, chan, size)
#    @class_id, @method_id = data.read(:short, :short)
#    p "Received method: #{@class_id},#{@method_id}"
#
#
#
#    if @class_id == 10 && @method_id == 10
#      @version_major, @minor = data.read(:octet, :octet)
#    end
#    p "B"
#    puts @major, @minor
#
#    @prop = data.read(:table)
#    p "C"
#    p @prop
#
#    exit
#
#  end
#
#end

end

%Q((

:connection
start
start-ok
secure
secure-ok
tune
tune-ok
open
open-ok
close
close-ok

:channel
open
open-ok
flow
flow-ok
alert
close
close-ok

:access
request
request-ok

:exchange

:queue

:basic

:file

:stream

:tx

:dtx

:tunnel

:test



))
