require 'gserver'
require 'stringio'

module NickelSilver
  module Server
    
    # = Summary
    # An implementation of the LoconetOverTcp protocol version 1 for use with the
    # LocoBuffer-USB awailable from RR-CirKits (http://www.rr-cirkits.com).
    #
    # This simple protocol allows clients connected via TCP to access a LocoNet netowrk.
    # Both sending and receiving of packets is supported.
    #
    # Author::    Tobin Richard (mailto:tobin.richard@gmail.com)
    # Copyright:: Copyright (c) 2008
    # License::   Distributes under the same terms as Ruby
    #
    # = Usage
    # The following creates a server listening on the default port of 5626 ('loco' spelt on a phone keypad)
    # using a LocoBuffer-USB connected to the serial port <tt>tty.serialport</tt>.
    #
    #   require 'rubygems'
    #   require 'nickel-silver-server'
    #   
    #   # connect to a LocoBufferUSB on the virtual serial port /dev/tty.serialport
    #   interface = NickelSilver::Server::Interface::LocoBufferUSB.new( '/dev/tty.serialport' )
    #   
    #   # create a server using the default port (i.e. 5626, 'loco' spelt on a phone keypad)
    #   # using our freshly connected LocoBuffer-USB
    #   server = NickelSilver::Server::LocoNetServer.new( interface )
    # 
    #   # start the server
    #   server.start
    # 
    #   # wait for the server to stop before exiting
    #   server.join
    #
    # If you want logging of connections, disconnections and other activity then
    # add <tt>server.audit = true</tt> before <tt>server.start</tt>.
    # 
    # = Protocol
    # For full details of the LoconetOverTcp protocol see
    # http://loconetovertcp.sourceforge.net/Protocol/LoconetOverTcp.html
    #
    # Information is exchanged between the server and clients as plain ASCII strings. The server
    # ignores invalid commands and empty lines.
    #
    # Clients may send the following commands to the server, as per the protocol specification:
    #
    # SEND Send a packet out over the LocoNet connection. The packet is not checked for correctness
    # before transmission. E.g. <tt>SEND a0 2f 00 70</tt>
    # 
    # The server may send the following information to clients, as per the protocol specification:
    #
    # VERSION: Sent to new clients immediately after they connect. The string which follows
    # describes the LocoNetOverTcp server's name and version.
    # E.g. <tt>VERSION NickelSilver version 0.1</tt>
    #
    # RECEIVE: Sent when a packet is received by the LocoBuffer-USB. E.g. <tt>RECEIVE 83 7c</tt>
    #
    # SENT: Sent to clients after an attempt has been made to process a SEND command. First
    # parameter is always <tt>OK</tt> or <tt>ERROR</tt> and may be followed by a string describing
    # details fo the transmission. E.g. <tt>SENT ERROR Could not communicate with LocoBuffer-USB</tt>
    #
    class LocoNetServer < GServer
      
      # Creates a new LocoNetOverTCP server.
      # 
      # You must supply an interface object and you may specify a port if the default of 5626
      # does not suit your environment.
      #
      # See the full documentation for this class for an exmaple using the LocoBuffer-USB.
      def initialize( interface, tcp_port=5626, *args )
        # we maintain a list of clients to be notified of LocoNet packets
        @clients = []
    
        # we will require access to the interface's buffers
        @interface = interface
  
        # start the interface buffering in another thread
        Thread.new { @interface.run }
  
        # process incoming packets in another thread
        Thread.new { process_packets }
    
        super( tcp_port, *args )
      end
  
      private
  
      # Serve a client.
      #
      # The client is registered with the server so it may be notified of LocoNet packets.
      #
      # Only this method may read from clients.
      def serve( io )
        # create a mutex to control access to this clients IO
        semaphore = Mutex.new
    
        # store the client and mutex for notification of LocoNet packets
        client = { :io => io, :mutex => semaphore }
        @clients << client
    
        # ouput VERSION to client
        semaphore.synchronize do
          io.puts( 'VERSION NickelSilver version 0.1' )
        end
    
        # read, execute loop
        loop do
          # get any pending input
          # if nil is returned then the client must have disconnected
          line = io.gets
          break if line.nil?
      
          command = line.split( ' ' )
      
          # LocoNet over TCP Version 1 only supports a single command, SEND
          # ignore all other commands/lines
          if command[0] == 'SEND'
            # convert command into bytes
            packet = command[ 1..command.length ]
            packet.map! { |b| b.to_i(16) }
        
            # send packet to loconet
            begin
              send_packet( packet )
              semaphore.synchronize do
                io.puts( 'SENT OK' )
              end
            rescue
              semaphore.synchronize do
                io.puts( 'SENT ERROR' )
              end
            end          
          end
        end
    
        # client has disconnected, remove it from the notification list
        @clients.delete( client )
      end
  
      # Send a packet to the LocoBuffer-USB connection.
      #
      # Does not check the packet format, checksum or anything else.
      #
      # Waits for the the packet sent to be RECEIVE'd back from the LocoBuffer
      def send_packet( packet )
        # create a pipe and mutex and add ourselves as a fake client so we can
        # check the packet is RECEIVE'd back by the LocoBuffer-USB
        reader, writer = IO.pipe
        client = { :io => writer , :mutex => Mutex.new }
        @clients << client
    
        # output the bytes
        @interface.io_mutex.synchronize do
          @interface.output_buffer += packet
        end
    
        # keep waiting for packets either for 2 seconds passes or we get a match
        start = Time.now
        matched = false
        until Time.now - start > 2.0 || matched
          # break it up and remove the leading RECEIVE
          if select( [reader], nil, nil, 0 )
            in_packet = reader.gets().split( ' ' )
            in_packet.delete_at( 0 )
            in_packet.map! { |b| b.to_i(16) }
        
            # check for a match
            matched = in_packet == packet
          end
        end
    
        # remove the fake client from the notification list
        @clients.delete( client )
    
        # raise an exception if the packet didn't send
        raise "Did not receive echo from LocoBuffer" unless matched
      end
  
      # Determine if a packet is complete. That is, determine if it has the correct
      # length as determined by its opcode (and possibly its second byte)
      def packet_complete?( packet )
        # if less than two bytes packet can't be finished
        return false if packet.length < 2
    
        # Determine correct length. See LocoNet Personal Use Edition 1.0 for
        # information on packet lengths.
        case 0b0110_0000 & packet[0]
          when 0b0000_0000 # two byte packet
            packet.length == 2
          when 0b0010_0000 # four byte packet
            packet.length == 4
          when 0b0100_0000 # six byte packet
            packet.length == 6
          when 0b0110_0000 # lower seven bits of second byte are message length
            packet.length == packet[1]
        end
      end
  
  
      # Process incoming packets and notficy clients.
      def process_packets
        packet = []
        loop do
          # wait for data in the buffer
          # sleep long enough to avoid pegging the CPU 
          while @interface.input_buffer.empty?
            sleep(0.1)
          end
      
          # get the next byte out of the buffer
          byte = 0
          @interface.io_mutex.synchronize do
            byte = @interface.input_buffer.shift
          end
                  
          # if this is the first byte it must have its msb set
          packet << byte unless packet.empty? && byte < 0b1000_0000
      
          # if we somehow got another opcode before completing a packet
          # then dump the current broken packet and start over
          packet = [byte] if byte >= 0b1000_0000
      
          # notify clients if the packet is complete
          if packet_complete?( packet )
            notify_clients( packet )
        
            # reset cuurent packet
            packet = []
          end
        end
      end
  
      # Notify all clients of a received packet.
      def notify_clients( packet )
        @clients.each do |client|
          client[:mutex].synchronize do
            client[:io].puts( 'RECEIVE ' + packet.map{ |b| format( '%02x', b ) }.join( ' ' ) )
          end
        end
      end
    end
    
  end
end