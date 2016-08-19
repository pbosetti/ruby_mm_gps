# Local Exception class.
class MmGPSException < Exception; end

# Manage connection and data decoding with a MarvelMind beacon or hedgehog.
module MmGPS
  # Checks a sbuffer for valid CRC16.
  # 
  # @param str [String] the buffer to be checked
  # @return [Bool] true if the buffer is self-consistent
  def self.valid_crc16?(str)
    crc16(str) == 0
  end
  
  # Parse the given buffer according to the MarvelMind protocol.
  # See http://www.marvelmind.com/pics/marvelmind_beacon_interfaces_v2016_03_07a.pdf
  #
  # @param buf [String] the String buffer to be parsed
  # @return [Hash|Array] if the system is running, return a Hash with
  #   timestamp, coordinates, and error code (data code 0x0001). Otherwise returns an Array of Hashes for beacons status (data code 0x0002).
  def self.parse_packet(buf)
    raise MmGPSException, "Invalid CRC" unless valid_crc16?(buf)
    # warn "Invalid CRC" unless valid_crc16?(buf)
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
      raise MmGPSException, "Unexpected packet type #{header[2]}"
    end
    return result
  end
end