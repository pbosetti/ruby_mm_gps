module MmGps
  def self.valid_crc16?(str)
    crc16(str) == 0
  end
end