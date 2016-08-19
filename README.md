# MmGPS
[![Gem Version](https://badge.fury.io/rb/mm_gps.svg)](https://badge.fury.io/rb/mm_gps)

Ruby interface to [MarvelMind Indoor GPS System](http://www.marvelmind.com).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mm_gps'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mm_gps

## Usage

Simple usage example:

```ruby
require 'mm_gps'

PORT = "/dev/cu.usbmodem1411"
BAUD = 115200 # SerialPort class does not support non-standard 500 kbps

beacon = MmGPS::Beacon.new(PORT, BAUD)
beacon.trap # installs signal handler for CTRL-C

puts "Syncing..."
begin
  beacon.sync # discards any byte until the starting sequence "\xFFG" arrives
rescue MmGPSError => e
  puts "Packet Error: #{e.inspect}, reason: #{e.data[:reason]}"
  puts "Packet: #{MmGPS.hexify(e.data[:packet])}"
rescue IOError => e
  puts "Port closed #{e.inspect}"
  exit
end

puts "Reading..."
while not beacon.closed? do
  begin
    p beacon.get_packet
  rescue MmGPSError => e
    puts "Packet Error: #{e.inspect}, reason: #{e.data[:reason]}"
    puts "Packet: #{MmGPS.hexify(e.data[:packet])}"
  rescue IOError => e
    puts "Port closed #{e.inspect}"
    exit
  end
end
```

## Contributing

Bug reports and pull requests are welcome [on GitHub ](https://github.com/pbosetti/ruby_mm_gps).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

