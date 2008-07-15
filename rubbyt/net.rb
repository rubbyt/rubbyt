
require 'socket'

module Rubbyt

module NonBlockingSocket

  include Socket::Constants

  def socket_connect
    @last_recv = nil
    @last_send = nil
    @socket = Socket.new(AF_INET, SOCK_STREAM, 0)
    sockaddr = Socket.sockaddr_in(port, host)
    begin
      @socket.connect_nonblock(sockaddr)
    rescue Errno::EINPROGRESS
      IO.select(nil, [@socket])
      begin
        socket.connect_nonblock(sockaddr)
      rescue Errno::EISCONN
      end
    end
  end

  def recv(blocking=false)
    begin
      while true
        @recv_buffer.rewind!
        received = socket.recv_nonblock(4096)
        raise(AMQPIncompleteFrame,:nothing_received) unless received
        @recv_buffer += received
        @last_recv = Time.now

        raise(AMQPIncompleteFrame,:header) if @recv_buffer.length < 7
        type, channel, size = @recv_buffer.read(:octet, :short, :long)
        raise(AMQPIncompleteFrame,:payload) if @recv_buffer.length < size+8
        raise AMQPBadFrame unless @recv_buffer[size+7] == AMQP_FRAME_END

        m = AMQPMethod.build_from_frame(recv_buffer[7..size+7], type,
                                        channel, size)
        @recv_buffer = @recv_buffer[m.size+8..-1]
        return m
      end
    rescue AMQPIncompleteFrame, Errno::EAGAIN
      if blocking
        IO.select([@socket])
        retry
      end
    end
  end

  def send(blocking=false)
    begin
      unless @send_buffer.empty?
        written = socket.write_nonblock(@send_buffer)
        @last_send = Time.now
        @send_buffer = @send_buffer[written..-1]
      end
      unless @frame_buffer.empty?
        @send_buffer << @frame_buffer.shift.pack
        return send(blocking)       # recursion - beware
      end
      raise if blocking && !@send_buffer.empty? && !@frame_buffer.empty?
    rescue
      if blocking
        IO.select([socket])
        retry
      end
    end
  end


end

end
