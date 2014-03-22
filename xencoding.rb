require 's20'
module XEncoding
  class Encoding
    CP = 65001
    def self.encode(str)
      Seiran20.to_wc(str, self::CP)
    end
    def self.decode(str)
      Seiran20.to_mb(str, self::CP)
    end
  end

  class GBK < Encoding
    CP = 936
  end

  class OEM < Encoding
    CP = 0
  end

  class UTF8 < Encoding
  end

  def self.find(a)
    b = XEncoding.constants.grep(/#{a.downcase}/i)
    if b[0]
      const_get(b[0])
    else
      raise raise "No encoder #{a} found"
    end
  end
end

class String
  attr_accessor :xencoding
  def xencoding
    @xencoding ||= XEncoding::UTF8   
  end

  def xencode(a)
    u = xencoding.encode(self)
    XEncoding.find(a).decode(u)
  end

  
end