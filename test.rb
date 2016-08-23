#!/usr/bin/env ruby
require 'mm_gps'

PORT = "/dev/cu.usbmodem1411"
BAUD = 115200 # SerialPort class does not support non-standard 500 kbps

beacon = MmGPS::Beacon.new(PORT, BAUD)
beacon.trap # installs signal handler for CTRL-C

# Standard each loop. Type CTRL-C for interrupting it
beacon.each do |packet|
  p packet
end


# Use the enumerator:
beacon.reopen      # Needed, since CTRL-C in previous example also closes the Serialport connection
enum = beacon.each # gets the Enumerator
p enum.take 10     # Next 10 packets from enum

puts "Exiting"