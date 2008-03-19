$:.unshift File.dirname(__FILE__)

require 'locobufferusb'
require 'loconetserver'

module NickelSilver
  module Server
    
    # An interface class should provide the following:
    # * Store incoming packets as FixNums representing bytes in a buffer array
    # * Send outgoing bytes (represented as FixNums in a buffer array) to LocoNet
    # * Use a Mutex to lock access to the buffers when in use (remember Nickel-Silver is multithreaded)
    # * Provide a method that causes your interface to start collecting packets
    #
    # The interface is simple. Only the following public methods are needed:
    # * Accessors for input_buffer, output_buffer and io_mutex
    # * run() which starts buffering
    #
    # How you do this will depend upon your hardware. Take a look at the LocoBufferUSB class to get
    # an idea of how it might be done.
    #
    # A stub driver might look like the following...
    #
    #   class SomeLocoNetInterface
    #     attr_accessor :input_buffer, :output_buffer, :io_mutex
    #   
    #     def initialize
    #       # these may be modified at any time by the server
    #       @input_buffer = []
    #       @output_buffer = []
    #   
    #       # only make changes when locked using @io_mutex
    #       @io_mutex = Mutex.new
    #     end
    #   
    #     def run
    #       loop do
    #         # get incoming bytes
    #         if byte_waiting?
    #           @io_mutex.synchronize do
    #             # byte getting code here
    #             @input_buffer << get_byte
    #           end
    #         end
    #   
    #         # send outgoing bytes
    #         until @output_buffer.empty? do
    #           @io_mutex.synchronize do
    #             # send a byte
    #             send_byte( @output_buffer.shift )
    #           end
    #         end
    #       end
    #     end
    #   
    #   end
    #
    module Interface
    end
    
  end
end