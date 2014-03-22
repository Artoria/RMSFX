require 'C:/RMSFX/rmsfx'

module RGSSY
  require 's20'
  
  class SourceCode
    include Seiran20
    attr_accessor :text, :handle
    
    
    def initialize(id)
      @id           = id
      refresh
    end
    
    def refresh
      self.text,self.handle = readmodule(@id)
      api('Kernel32', 'VirtualProtect').call(self.handle, self.text.size, 0x40, "RGBA")
    end
    
    
    class Finder
      def initialize(obj, range = 0...obj.text.size)
        @self = obj
        @range = range
      end
      
      def first
        @range.first
      end
      
      def last
        @range.exclude_end? ? @range.last - 1 : @range.last
      end
      
      def find_raw_string(a)
        k = first - 1
        ke = last
        ret = []
        while (k = @self.text.index(a, k+1)) && k < ke
           ret << k
        end
        ret
      end
    
      def find_raw_strings(a)
        ret = []
        a.each{|x|
          ret << find_raw_string(x)
        }
        ret.flatten
      end
    end
    
    def find(a, range = 0...self.text.size)
      f = Finder.new(self, range)
      case a
        when String
          f.find_raw_string(a)      
        when Integer
          f.find_raw_string([a].pack("L"))
        when Array
          case a[0]
            when :push
              u = f.find_raw_string(a[1])
              f.find_raw_strings(u.map{|x| "\x68" + [x].pack("L")})
            when :pushofs
              u = f.find_raw_string(a[1])
              f.find_raw_strings(u.map{|x| "\x68" + [self.handle + x].pack("L")})
          end
      end
    end
    
    alias [] find
    
    def write_single(a, buf)
      self.text[a, buf.length] = buf
      writemem(self.handle + a, buf.length, buf)
      refresh
      nil
    end
    
    def read(a, len)
      readmem(a + self.handle, len)
    end
    
    def readrel(a)
      readmem(a + self.handle, 4).unpack("L").first + a + self.handle + 4
    end

    
    def write(a, buf)
      a.each{|x| write_single(x, buf) }
    end
    
    
  end
  HANDLES = Hash.new{|h, k|
      h[k] = SourceCode.new(k)
    }
    
  RGSS = HANDLES[Seiran20::ID_RGSS]
  Game = HANDLES[0]
end

