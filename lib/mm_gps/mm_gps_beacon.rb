module MmGPS  
  class Beacon
    START_TOKEN = "\xFFG".force_encoding(Encoding::BINARY)
    EMPTY = ''.force_encoding(Encoding::BINARY)
    
    def initialize(port, baud = 115200)
      @sp = SerialPort.new(port, "baud" => baud)
      @sp.read_timeout = 1000 #1 sec
      @sp.binmode
    end
    
    def trap
      Signal.trap("INT") do
        @sp.close
        puts "Beacon port: #{@sp.inspect}"
      end
    end

    def close
      @sp.close
    end
    
    def closed?
      return @sp.closed?
    end
    
    def sync
      buf = EMPTY
      begin
        buf << (@sp.read(1) || EMPTY)
        buf = buf[-2..-1] if buf.size > 2
      end while buf != START_TOKEN
    end
    
    def get_raw_packet
      buf = START_TOKEN.dup
      while true do
        buf << (@sp.read(1) || EMPTY)
        break if buf[-2..-1] == START_TOKEN
      end
      return buf[0...-2]
    end
    
    def get_packet
      return MmGPS::parse_packet(self.get_raw_packet)
    end
    
  end
end
