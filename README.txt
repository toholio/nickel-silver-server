= nickel-silver-server

* http://github.com/toholio/nickel-silver-server/

== DESCRIPTION:

A Ruby server implementing the LocoNetOverTCP protocol allowing remote clients to connect to Digitrax based model railway layouts. Currently supports version 1 of the protocol.

== FEATURES/PROBLEMS:

* Complete support for LocoNetOverTCP version 1
* Multithreaded server based on GServer
* Easily extended to use new hardware interfaces

== SYNOPSIS:

  require 'rubygems'
  require 'nickel-silver-server'
  
  # connect to a LocoBufferUSB on the virtual serial port /dev/tty.serialport
  interface = LocoBufferUSB.new( '/dev/tty.serialport' )
  
  # create a server using the default port (i.e. 5626, 'loco' spelt on a phone keypad)
  # using our freshly connected LocoBuffer-USB
  server = LocoNetServer.new( interface )
  
  # start the server
  server.start
  
  # wait for the server to stop before exiting
  server.join

== REQUIREMENTS:

The toholio-serialport gem is needed to connect with LocoBuffer-USB hardware. http://github.com/toholio/ruby-serialport/

If you already have an old version of the ruby-serialport library installed you may need to uninstall it first as it will not load under RubyGems.

== INSTALL:
If you have not added GitHub as a gem source you will need to do so first:
* gem sources -a http://gems.github.com

To install the actual gem:
* sudo gem install toholio-nickel-silver-server

== LICENSE:

Nickel Silver is distributed under the same terms as Ruby.

Copyright (c) 2008 Tobin Richard
