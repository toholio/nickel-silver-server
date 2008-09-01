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
      #   lb.run
      #   
      #   loop do
      #     sleep(1)
      #     
      #     until lb.input_buffer.empty? do
      #       lb.io_mutex.synchronize do
      #         puts "Got byte #{ format( '%02x', lb.input_buffer.shift ) } from LocoNet"
      #       end
      #     end
      #   end
      #
      class LocoBufferUSB
        attr_accessor :input_buffer, :output_buffer, :io_mutex
  
        # Connect to a LocoBuffer-USB using the specified serial port.
        def initialize( serial_port )
          @locobuffer = SerialPort.new( serial_port, 57_600 )
    
          # these may be modified at any time by the server
          @input_buffer = []
          @output_buffer = []
    
          # only make changes when locked using @io_mutex
          @io_mutex = @iomutex = Mutex.new
        end
  
        # Handle packets moving in and out of the LocoBuffer-USB.
        def run
          loop do
            while select( [@locobuffer], nil, nil, 0 ) do
              @io_mutex.synchronize do
                @input_buffer << @locobuffer.getc
              end
            end
  
            # puts "outbuf length = #{output_buffer.length}"
            until output_buffer.empty? do
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
