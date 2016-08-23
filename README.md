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

beacon = MmGPS::Beacon.new(PORT, baud: BAUD)
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
```

## Contributing

Bug reports and pull requests are welcome [on GitHub ](https://github.com/pbosetti/ruby_mm_gps).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

