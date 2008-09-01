require 'serialport'

module NickelSilver
  module Server
    module Interface
      
      # A simple IO wrapper for the LocoBuffer-USB.
      #
      # See the documentation for LocoNetServer for details on how this should be used.
      #
      # = Stand-alone usage
      #   lb = LocoBufferUSB.new( '/dev/ttys0' )
      #   
      #   runner = Thread.new do
      #     lb.run
      #   end
      #   
      #   loop do
      #     sleep(1)
      #     
      #     lb.read.each do |byte|
      #       puts "Got byte #{ format( '%02x', byte ) } from LocoNet"
      #     end
      #   end
      #
      class LocoBufferUSB
        # Connect to a LocoBuffer-USB using the specified serial port.
        def initialize( serial_port )
          @locobuffer = SerialPort.new( serial_port, 57_600 )
    
          # these may be modified at any time by the server
          @input_buffer = []
          @output_buffer = []
    
          # only make changes when locked using @io_mutex
          @io_mutex = Mutex.new
        end

        # Returns an array of bytes read since the last time this method was called.
        def read
          inward = []
          @io_mutex.synchronize do
            inward += @input_buffer
            @input_buffer = []
          end
          inward
        end

        # Adds an array of bytes to the data waiting to be sent.
        def write( bytes )
          @io_mutex.synchronize do
            @output_buffer += bytes
          end
        end
  
        # Handle packets moving in and out of the LocoBuffer-USB.
        def run
          loop do
            while select( [@locobuffer], nil, nil, 0 ) do
              @io_mutex.synchronize do
                @input_buffer << @locobuffer.getc
              end
            end
  
            until @output_buffer.empty? do
              @io_mutex.synchronize do
                @locobuffer.putc( @output_buffer.shift )
              end
            end
          end
        end
      end
    
    end
  end
end
