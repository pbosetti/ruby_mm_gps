#!/usr/bin/env ruby
require 'mm_gps'

PORT = "/dev/cu.usbmodem1411"
BAUD = 115200 # SerialPort class does not support non-standard 500 kbps

beacon = MmGPS::Beacon.new(PORT, baud: BAUD)
beacon.trap # installs signal handler for CTRL-C

# Standard each loop. Type CTRL-C for interrupting it
File.open("dump.bin", 'w') do |f|
  beacon.each do |packet, raw|
    p packet
    puts MmGPS::hexify(raw)
    f.print(raw)
  end
end

# Use the enumerator:
beacon.reopen      # Needed, since CTRL-C in previous example also closes the Serialport connection
enum = beacon.each # gets the Enumerator
p enum.take 10     # Next 10 packets from enum

puts "Exiting"