#!/usr/bin/env ruby
class BufferError < RuntimeError; end

module MmGPS
  # A general abstraction for dealing with character streams.
  #
  # @example Typical usage:
  #   buffer = Buffer.new(START_TOKEN)
  #   buffer.when_updating do
  #     @sp.read(1) # @sp is an IO instance
  #   end
  #   # more code...
  #   pkt = buffer.next
  # 
  class Buffer
    include Enumerable
    attr_reader :separator, :stop_packet
    attr_reader :buffer, :fiber
    
    def initialize(sep="\xFF")
      @update = lambda { empty }
      @encoding = Encoding::BINARY
      fiber_init
      self.separator = sep
      self.clear
    end
    
    # Set the {#separator} bytes sequence, as a String in {#encoding} format.
    # 
    # @param s [String] the separator string, automatically converted into {#encoding}
    def separator=(s)
      @separator = s.force_encoding(@encoding)
    end
    
    # Clear the {#buffer} and return its last content.
    # 
    # @return [String] the last buffer content
    def clear
      tmp = @buffer
      @buffer = empty
      return tmp
    end
    
    # Sets the block to be executed for updating the {#buffer}. Typically, 
    # this block must read one single byte and return it. Queuing into the 
    # {#buffer} is automatically performed.
    # @example To read from a serialport instance +@sp+:
    #   buffer.when_updating do
    #     @sp.read(1)
    #   end
    # 
    # @param block [Proc] the block (with no parameters) that must return a new character every time it is called
    def when_updating(&block)
      @update = block
    end
    
    # Call the block set with {#when_updating} and queues its returned byte into {#buffer}
    def update
      @buffer << (@update.call || empty)
    end
    
    # Return the next available packet
    # 
    # @return [String] the next available packet
    def next
      @fiber.resume
    end
    
    # Iterates a block over incoming packets
    # 
    # @yield [pkt]
    # @yieldparam pkt [String] the next packet
    # @return [Enumerator] an {Enumerator} when called without block
    def each
      return enum_for(:each) unless block_given?
      loop do
        yield self.next
      end
    end
  
    private
    def fiber_init
      @fiber = Fiber.new do
        loop do # over packets
          pkt = empty
          loop do # over chars
            begin
              self.update
            rescue BufferError
              Fiber.yield self.clear #yelds @buffer AND clears it!
            end
            if @buffer.start_with?(@separator) &&
               @buffer.end_with?(@separator) && 
               @buffer != @separator then # end of packet
              pkt = @buffer.slice!(0...-@separator.length)
              break
            elsif @buffer.end_with?(@separator) then # Incomplete packet
              @buffer.slice!(0...-@separator.length)
            end
          end
          Fiber.yield pkt
        end
        warn "Exiting fiber!"
      end
    end
  
    def empty
      String.new("", encoding:@encoding)
    end
  
  end
end

if $0 == __FILE__ then
  require 'pry'
  
  str = "OKjhagshj asjhgOKjhjhg jhgasjdhg aOKjhahg ashg jhgjhaOKstopppp"
  cb = MmGPS::Buffer.new
  cb.separator = "OK"
  cb.when_updating do
    raise BufferError if str.empty?
    str.slice!(0...1)
  end
  p cb
  
  binding.pry
end