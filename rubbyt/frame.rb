
module Rubbyt

class AMQPMethod
  class << self
    def find_all_by_class_id
    end

    def find_all_by_class_name
    end

    def find
    end
  end

  def initialize(class_id, method_id, class_name, method_name, &block)
    @class_id = class_id
    @method_id = method_id
    @class_name = class_name
    @method_name = method_name
    @fields = Array.new
    block.call(self)

    # FIXME add self to lookup tables/maps
  end

  def field(name, type)
    @fields << FIXME
  end

  def unpack(s)
  end

  def pack
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








String.class_eval do
  def rewind
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
    table = Hash.new
    table_data = read(:longstr)
    p table_data

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
          p "Unknown type in _read_table: #{type}"
          exit
      end
      table[key] = val
    end
    return table
  end

end


class Method
  attr_reader :size, :class_id, :method_id

  def self.build_from_frame(data)
    raise AMQPIncompleteFrame(:header) if data.length < 7
    type, chan, size = data.read(:octet, :short, :long)
    raise AMQPIncompleteFrame(:payload) if data.length < size+8
    raise AMQPIncompleteFrame(:frame_end) if data[size+7] != AMQP_FRAME_END

    Method.new(data[7..size+7], type, chan, size)
  end

  def initialize(data, type, chan, size)
    @class_id, @method_id = data.read(:short, :short)
    p "Received method: #{@class_id},#{@method_id}"

    if @class_id == 10 && @method_id == 10
      @version_major, @minor = data.read(:octet, :octet)
    p "B"
    puts @major, @minor

    @prop = data.read(:table)
    p "C"
    p @prop

    exit

  end
end

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
