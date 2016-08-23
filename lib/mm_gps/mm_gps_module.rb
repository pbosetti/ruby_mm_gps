# Local Exception class.
#
# The +@data+ attribute holds a Hash with informative content. In particular, 
# +@data [:reason]+ holds a Symbol providing the internal error code, currently
# one of the following:
# 
# - +:notype+   when the packet type code is neither 1 nor 2
# - +:nocrc+    when the CRC16 check fails
# - +:noavail+  when the serialport was not available for reading (timeout)
# 
# Typically, the last raw buffer is available in human readable format as:
# 
#     rescue MmGPSError => e
#       puts MmGPS::hexify(e.data[:packet])
#     end
# 
class MmGPSError < RuntimeError
  attr_reader :data
  def initialize(msg="Error in MmGPS class", data={})
    @data = data
    super(msg)
  end
end

# Manage connection and data decoding with a MarvelMind beacon or hedgehog.
module MmGPS
  # Checks a sbuffer for valid CRC16.
  # 
  # @param str [String] the buffer to be checked
  # @return [Bool] true if the buffer is self-consistent
  def self.valid_crc16?(str)
    crc16(str) == 0
  end
  
  # Returns a HEX description of a binary buffer
  #
  # @param buf [String] the input buffer
  # @return [String] the HEX description
  def self.hexify(buf)
    len = buf.length
    return (("%02X " * len) % buf.unpack("C#{len}")).chop
  rescue NoMethodError
    return '--'
  end
  
  # Parse the given buffer according to the MarvelMind protocol.
  # See http://www.marvelmind.com/pics/marvelmind_beacon_interfaces_v2016_03_07a.pdf
  #
  # @param buf [String] the String buffer to be parsed
  # @return [Hash|Array] if the system is running, return a Hash with
  #   timestamp, coordinates, and error code (data code 0x0001). Otherwise returns an Array of Hashes for beacons status (data code 0x0002).
  def self.parse_packet(buf)
    unless valid_crc16?(buf) then
      raise MmGPSError.new("Invalid CRC", {reason: :nocrc, packet:buf, crc:("%04X" % crc16(buf[0...-2]))}) 
    end
    header = buf[0..5].unpack('CCS<C')
    if header[2] == 1 then # Regular GPS Data
      result = {}
      payload = buf[5...16].unpack('L<s<3C')
      result = %I(ts x y z f).zip(payload).to_h
      result[:ts] /= 64.0
      %I(x y z).each {|k| result[k] /= 100.0}
    elsif header[2] == 2 then # Frozen
      len = buf[5].unpack('C')[0]
      result = []
      len.times do |i|
        offset = 6 + i * 8
        payload = buf[offset...(offset + 8)].unpack('Cs<3C')
        result << %I(address x y z reserved).zip(payload).to_h
        %I(x y z).each {|k| result.last[k] /= 100.0}
      end
    else
      unless valid_crc16?(buf) then
        raise MmGPSError.new("Unexpected packet type #{header[2]}",
          {reason: :notype, packet:buf, crc:("%04X" % crc16(buf[0...-2])), type:header[2]}) 
      end
    end
    return result
  end
end