= nickel-silver-server

* http://rubyforge.org/projects/nickel-silver/

== DESCRIPTION:

Ruby, literally, on rails! A Ruby implementation of the LocoNetOverTCP protocol allowing remote clients to connect to Digitrax based model railway layouts. Also included are a number of tools for LocoNet logging and locomotive control.

== FEATURES/PROBLEMS:

* Complete support for LocoNetOverTCP version 1

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

* ruby-serialport is needed to connect with LocoBuffer-USB hardware http://rubyforge.org/projects/ruby-serialport/ 

== INSTALL:

* sudo gem install nickel-silver-server

== LICENSE:

Nickel Silver is distributed under the same terms as Ruby.

Copyright (c) 2008 Tobin Richard