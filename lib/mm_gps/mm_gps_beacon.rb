module MmGPS
  
  # Main interface. Represents a connection to a MarvelMind beacon/hedgehog. 
  # You may want (and can) to have more than one instance.
  # 
  # @example Typical usage:
  #   beacon = MmGPS::Beacon.new(PORT, BAUD)
  #   beacon.trap # installs signal handler for CTRL-C
  #   
  #   # Standard each loop. Type CTRL-C for interrupting it
  #   beacon.each do |packet|
  #     p packet
  #   end
  # @example Using the enumerator:
  #   # Use the enumerator:
  #   beacon.reopen      # Needed, since CTRL-C in previous example also closes the Serialport connection
  #   enum = beacon.each # gets the Enumerator
  #   p enum.take 10     # next 10 packets from enum
  # 
  class Beacon
    include Enumerable
    START_TOKEN = "\xFFG"
    attr_reader :last_pkt
    attr_reader :port, :baud
    
    # Open a new connection on the given serial port. It also encapsulates
    # the underlying SerialPort object instance, setting a read timeout of 1 s
    # and enabling the binary mode.
    # 
    # @param port [String] 'COM1' on Windows, '/dev/ttyNNN' on *nix
    # @param baud [Fixnum] baudrate, value must be supported by the platform
    def initialize(port, baud = 115200)
      @port, @baud = port, baud
      self.open
    end
    
    # Installs a signal handler for the given signal, default to +'SIGINT'+, 
    # which closes the serialport connection. Further readings are likely to
    # trigger an IOError.
    # 
    # @param signal [String] the signal to be trapped, default to +'SIGINT'+
    def trap(signal="INT")
      Signal.trap(signal) do
        @sp.close
        puts "\nBeacon port: #{@sp.inspect}"
      end
    end
    
    # Close the serialport
    # 
    # @return [Beacon] self
    def close
      @sp.close unless (!@sp || @sp.closed?)
      return self
    end
    
    # Open the serialport connection with {#port} at {#baud} rate. It also
    # resets internals to a clean state.
    # 
    # @return [Beacon] self
    def open
      self.close 
      @sp = SerialPort.new(@port, "baud" => @baud)
      @sp.read_timeout = 1000 #1 sec
      @sp.binmode
      @last_pkt = ''.force_encoding(Encoding::BINARY)
      @buffer = Buffer.new(START_TOKEN)
      @buffer.when_updating do
        @sp.read(1)
      end
      return self
    end
    alias :reopen :open
    
    # Check wether the serialport is closed
    # 
    # @return [Bool] true if closed, false if open
    def closed?
      return @sp.closed?
    end
    
    # Reads and discards incoming bytes until the START_TOKEN marker is
    # received. Call this metod immediately after opening the connection
    # and before start reading the data.
    # 
    # @return [Beacon] self
    # @deprecated No more needed, since this version automatically takes care of the incomplete packages.
    def sync
      warn "Beacon#sync is deprecated and no more necessary!"
      return self
    end
    
    # Iterates +block+ to each packet
    # 
    # @yield [pkt] the decoded packet
    # @yieldparam pkt [Hash|Array] the decoded packet as returned by +MmGPS#parse_packet+
    def each
      return enum_for(:each) unless block_given?
      loop do
        begin
          yield self.get_packet
        rescue MmGPSError => e
          warn "Packet Error: #{e.inspect}, reason: #{e.data[:reason]}"
          warn "Packet: #{MmGPS.hexify(e.data[:packet])}"
          if e.data[:reason] == :nocrc then
            warn "CRC16: #{e.data[:crc]}"
          end
        rescue IOError => e
          warn "Port closed #{e.inspect}"
          return
        end
      end
    end
    
    # Reads a raw packet.
    #
    # @return [String] a byte stream encoded with Encoding::BINARY
    # @raise [MmGPSError] when data are not available, setting +e.data [:reason]+ to +:noavail+
    def get_raw_packet
      pkt = @buffer.next
      if pkt.empty? then
        raise MmGPSError.new("Data unavailable", {reason: :noavail})
      end
      @last_pkt = pkt
      return @last_pkt
    end
    
    # Reads a raw packet, checks its CRC, and returns its contents as a Hash.
    # 
    # @return [Hash|Array] typically in the form +%I(ts x y f).zip(payload).to_h+
    # @raise [MmGPSError] when CRC16 check does not pass, setting +e.data [:reason]+ to +:nocrc+
    def get_packet
      return MmGPS::parse_packet(self.get_raw_packet)
    end
    
  end
end
