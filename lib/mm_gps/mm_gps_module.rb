class GPSException < Exception; end

module MmGps
  def self.valid_crc16?(str)
    crc16(str) == 0
  end
  
  def self.parse_packet(buf)
    raise GPSException, "Invalid CRC" unless valid_crc16?(buf)
    header = buf[0...5].unpack('CCS>C')
    
    if header[2] == 1 then # Regular GPS Data
      result = {}
      payload = buf[5...16].unpack('L>S>3C')
      result = %I(ts x y z f).zip(payload).to_h
    elsif header[2] == 2 then # Frozen
      len = buf[5].unpack('C')[0]
      result = []
      len.times do |i|
        offset = 6 + i * 8
        payload = buf[offset...(offset + 8)].unpack('CS>3C')
        result << %I(address x y z reserved).zip(payload).to_h
      end
    else
      raise GPSException, "Unexpected packet type #{header[2]}"
    end
    return result
  end
end