#!/usr/bin/env ruby
require 'mm_gps'

PORT = "/dev/cu.usbmodem1411"
BAUD = 115200 # SerialPort class does not support non-standard 500 kbps

beacon = MmGPS::Beacon.new(PORT, BAUD)
beacon.trap # installs signal handler for CTRL-C

puts "Syncing..."
begin
  beacon.sync # discards any byte until the starting sequence "\xFFG" arrives
rescue MmGPSException => e
  puts "Packet Error: #{e.inspect}"
rescue IOError => e
  puts "Port closed #{e.inspect}"
  exit
end

puts "Reading..."
while not beacon.closed? do
  begin
    p beacon.get_packet
  rescue MmGPSException => e
    puts "Packet Error: #{e.inspect}"
  rescue IOError => e
    puts "Port closed #{e.inspect}"
    exit
  end
end
