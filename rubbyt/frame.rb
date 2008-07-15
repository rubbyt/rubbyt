
module Rubbyt

class AMQPMethod
  attr_reader :method_name, :class_name
  @@list = Array.new
  @@lookup = Hash.new
  @@lookup_by_sym = Hash.new

  class << self
    def build_from_frame(data, type, channel, size)
      class_id, method_id = data.read(:short, :short)
      m = AMQPMethod.create(class_id, method_id)
      m.update(:type => type, :channel => channel, :size => size)
      m.unpack(data)

      puts "\nBuilt AMQPMethod instance from frame:\n#{m.inspect}"
      return m
    end

    def create(klass, method)
      if klass.is_a?(Fixnum)
        return @@list[@@lookup[klass][method]].clone
      elsif klass.is_a?(Symbol)
        return @@list[@@lookup_by_sym[klass][method]].clone
      end
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
    @channel = 0
    @type = 1
    block.call(self)

    @@list << self
    @@lookup[class_id] ||= Hash.new
    @@lookup[class_id][method_id] = @@list.length - 1
    @@lookup_by_sym[class_name] ||= Hash.new
    @@lookup_by_sym[class_name][method_name] = @@list.length - 1

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
    fields.each { |fld| send("#{fld[0]}=", s.read(fld[1])) }
    self
  end

  def pack
    s = _pack(@class_id, :short) + _pack(@method_id, :short)
    fields.each { |fld| s << _pack(send(fld[0]), fld[1]) }
    _pack(@type, :octet) + _pack(@channel, :short) +
            _pack(s, :longstr) + _pack(AMQP_FRAME_END, :octet)
  end

  def _pack(data, type)
    case type
      when :octet
        return [data].pack("C")
      when :short
        return [data].pack("n")
      when :long
        return [data].pack("N")
      when :longlong
        # FIXME
      when :shortstr
        return [data.length].pack("C")+data
      when :longstr
        return [data.length].pack("N")+data
      when :timestamp
        # FIXME
      when :bit
        # FIXME
      when :table
        return _pack_table(data)
      else
        puts "FIXME unknown type #{type}"
        raise
    end
  end

  def _pack_table(t)
    s = ''
    t.each_pair do |key,val|
      p = _pack(key.to_s, :shortstr)
      if val.respond_to?(:chomp)
        # string
        p += 'S' + _pack(val, :longstr)
      else
        puts "FIXME _pack_table NOTIMPL"
      end
      s += p
    end
    _pack(s, :longstr)
  end
    
end

require 'rubbyt/methods'






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
