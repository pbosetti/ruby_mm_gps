module MmGPS
  
  # Main interface. Represents a connection to a MarvelMind beacon/hedgehog. 
  # You may want (and can) to have more than one instance.
  class Beacon
    START_TOKEN = "\xFFG".force_encoding(Encoding::BINARY)
    EMPTY = ''.force_encoding(Encoding::BINARY)
    attr_reader :last_pkt
    
    # Open a new connection on the given serial port. It also encapsulates
    # the underlying SerialPort object instance, setting a read timeout of 1 s
    # and enabling the binary mode.
    # 
    # @param port [String] 'COM1' on Windows, '/dev/ttyNNN' on *nix
    # @param baud [Fixnum] baudrate, value must be supported by the platform
    def initialize(port, baud = 115200)
      @sp = SerialPort.new(port, "baud" => baud)
      @sp.read_timeout = 1000 #1 sec
      @sp.binmode
      @last_pkt = ''.force_encoding(Encoding::BINARY)
      @buffer = EMPTY
    end
    
    # Installs a signal handler for the given signal, default to SIGINT, 
    # which closes the serialport connection. Further readings are likely to
    # trigger an IOError.
    # 
    # @param signal [String] the signal to be trapped, default to 'SIGINT'
    def trap(signal="INT")
      Signal.trap(signal) do
        @sp.close
        puts "\nBeacon port: #{@sp.inspect}"
      end
    end
    
    # Close the serialport
    def close
      @sp.close
    end
    
    # Check wether the serialport is closed
    # 
    # @return [Bool] true if closed, false if open
    def closed?
      return @sp.closed?
    end
    
    # Reads and discards incoming bytes until the START_TOKEN marker is
    # received. Call this metod immediately after opening the connection
    # and before start reading the data.
    def sync
      self.get_raw_packet
    rescue MmGPSError => e
    end
    
    # Reads a raw packet.
    #
    #  @return [String] a byte stream encoded with Encoding::BINARY
    def get_raw_packet
      loop do
        char = @sp.read(1)
        if char then
          @buffer << char
        else
          raise MmGPSError.new("Data unavailable", 
            {reason: :noavail, packet:@buffer}) 
        end
        break if @buffer.end_with?(START_TOKEN)
      end
      @last_pkt = @buffer.slice!(0...-(START_TOKEN.length))
      return @last_pkt
    end
    
    # Reads a raw packet, checks its CRC, and returns its contents as a Hash.
    # 
    # @return [Hash|Array] typically in the form +%I(ts x y f).zip(payload).to_h+
    def get_packet
      return MmGPS::parse_packet(self.get_raw_packet)
    rescue MmGPSError => e
      if e.data[:reason] == :noavail then
        return nil
      else
        raise e
      end
    end
    
  end
end
