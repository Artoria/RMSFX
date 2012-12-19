require 's20'
module CC
  TCC = Seiran20.lm('tcc')
  BUF = Seiran20.lm('buffer')

  class StringProc
    def initialize(text, alloc = BUF.alloc(16384))
      @text  = text
      @alloc = alloc
    end
    def call(*a) 
       to_proc.call *a
    end
    def error
       @ptr   = BUF.to_ptr @alloc
       Seiran20.readstr @ptr
    end
    def to_proc
      if !@proc
        @ptr   = BUF.to_ptr @alloc
        @addr  = TCC.compile @alloc, @text        
        if @addr && @addr != 0
          return @proc = Seiran20.callproc(@addr)
        else
          raise Seiran20.readstr @ptr
        end
      end
      @proc
    end
  end

  def self.allocbuf(size)
    x = BUF.alloc(size)
    yield x
    BUF.decref(x)
  end

  def self.allocbufs(*size)
    buf = size.map{|x| BUF.alloc(x)}
    yield buf
    buf.each{|x| BUF.decref x}
  end

  def self.fromBitmap(bitmap)
    CC::BUF.fromBitmap(bitmap)
  end
  
  INVERT = StringProc.new(<<-'EOF')
int func(int prebuf){
   if(!(prebuf & 1)) return 1;
   int **buf = (int **)(prebuf >> 1);
   int *addr = buf[0], len = (int)buf[1] / 4, *end = addr + len;
   while(addr != end){*addr++^=0xFFFFFF;}
   return 0;
}
EOF


    
end


