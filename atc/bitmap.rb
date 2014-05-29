Kernel.require 'c:/rmsfx/rmsfx'
require 'inline'
class Bitmap
  
  def self.compile(name, text)
    "int " << name << "(int argc, int *argv, int self){" <<
       text <<
    "return self;}"
  end
  
  
  
  def self.define_pixel_method name, lb = nil, &bl
    method_entry = lb || bl
    
    r,g,b,a = 
       CPPVar.new("((*pixel >> 16) & 0xFF)"),
       CPPVar.new("((*pixel >>  8) & 0xFF)"),
       CPPVar.new("((*pixel & 0xFF))"),
       CPPVar.new("((*pixel >> 24) & 0xFF)")
       
    r,g,b,a = method_entry.call(r,g,b,a)
    
    text = "((int)(%s) & 0xFF) << 16 | 
            ((int)(%s) & 0xFF) << 8  |
            ((int)(%s) & 0xFF) | 
            ((int)(%s) & 0xFF) << 24" % [r, g, b, a]
   eachpixel = "
            int *pixel = ((int ****)(self))[4][2][4];
            int *end  = ((int ****)(self))[4][2][3];
            int *copy = 
            while(pixel != end){
               *pixel++ = #{text};
            }
    "
    #msgbox compile(name.to_s, eachpixel) 
    inline do |builder|
        builder.c_raw compile(name.to_s, eachpixel)
    end
    
  end
  
  
  class SpecialMap
    def io
      @io
    end
    def initialize 
      @io = ""
    end
    def if(a)
      @io << "if (#{a}){"
        yield
      @io << "}"
    end
    def else
      @io << "else{"
        yield
      @io << "}"
    end
    class Math
      def method_missing(sym)
        CPPVar.new(sym.to_s)
      end
    end
    
    def math
      Math.new
    end
    def copySrc(x, y)
      @io << "*pixel = src(#{x}, #{y});
        r = ((*pixel >> 16) & 0xFF);
        g = ((*pixel >>  8) & 0xFF);
        b = ((*pixel) & 0xFF);
        a = ((*pixel >> 24) & 0xFF);
      "
    end
    def apply_kernel(k, ox, oy, opt = {:r => true, :g => true, :b => true, :a => true})
      cnt = 0
      @io << %{
      {
        #{"int kr = 0;" if opt[:r] }
        #{"int kg = 0;" if opt[:g] }
        #{"int kb = 0;" if opt[:b] }
        #{"int ka = 0;" if opt[:a] }
        
        #{
         (0...k.size).to_a.map{|j|
            (0...k[j].size).to_a.map{|i|
             "
              {
               int c = src(x + #{i - ox}, y + #{j - oy});
               #{ "kr += #{k[j][i]} * ((c >> 16) & 0xFF);" if opt[:r]}
               #{ "kg += #{k[j][i]} * ((c >>  8) & 0xFF);" if opt[:g]}
               #{ "kb += #{k[j][i]} * ((c) & 0xFF);" if opt[:b]}
               #{ "ka += #{k[j][i]} * ((c >> 24) & 0xFF);" if opt[:a]}
               #{cnt += k[j][i]; ''};
              }
             "
            }.join("\n")
          }.join("\n") 
        }
       #{ "r = kr / #{cnt == 0 ? 1 : cnt};" if opt[:r] }
       #{ "g = kg / #{cnt == 0 ? 1 : cnt};" if opt[:g] }
       #{ "b = kb / #{cnt == 0 ? 1 : cnt};" if opt[:b] }
       #{ "a = ka / #{cnt == 0 ? 1 : cnt};" if opt[:a]} 
        c_all();
         *pixel = 
                ((int)(r) & 0xFF) << 16 | 
                ((int)(g) & 0xFF) << 8  |
                ((int)(b) & 0xFF) | 
                ((int)(a) & 0xFF) << 24; 
        }
      }
    end
    %w[r g b a x y dest src].each do |var|
      define_method var       do CPPVar.new(var) end
      define_method "#{var}=" do |val| @io << "#{var} = #{val};\n" end
    end
  end
  def self.define_map_method name, lb = nil, &bl
    method_entry = lb || bl
    eachpixel = "
            void *(*malloc)(int) = #{Seiran20.funcaddr('msvcrt', 'malloc')};
            void (*memcpy)(void *, void *, int) = #{Seiran20.funcaddr('msvcrt', 'memcpy')};
            void (*free)(void *)  = #{Seiran20.funcaddr('msvcrt', 'free')};
            float (*hypot)(float a, float b)  = #{Seiran20.funcaddr('msvcrt', 'sqrt')};
            int *start = ((int ****)(self))[4][2][4];
            int *pixel = ((int ****)(self))[4][2][4];
            
            int width  = ((int ****)(self))[4][2][2][1];
            int height = ((int ****)(self))[4][2][2][2];            
            int *copy  = malloc(width * height * 4);
            int x     = 0;
            int y     = height - 1;
            int tx, ty;
            memcpy(copy, pixel, width * height * 4);
            int *end   = start +  ( height - 1 ) * width;
            int *end2  = copy  +  ( height - 1 ) * width;
            int *rend  = end + width;
            #define clamph(yy)  (ty = yy, ((ty > (height - 1)) ? (ty = height - 1) : 1), ((ty < 0) ? (ty = 0) : 1), ty)
            #define clampw(xx)  (tx = xx, ((tx > (width  - 1)) ? (tx = width  - 1) : 1), ((tx < 0) ? (tx = 0) : 1), tx)
            #define dest(x2, y2) (end [-(clamph(y2))*width+(clampw(x2))])
            #define src(x2, y2)  (end2[-(clamph(y2))*width+(clampw(x2))]) 
            #define clampch(a)  if (a > 255) a = 255; if (a < 0) a = 0;
            #define c_all() clampch(r);clampch(g);clampch(b);clampch(a)
            while(pixel != rend){
               int r, g, b, a;
              #{v = SpecialMap.new;  method_entry.call(v);  v.io}
              c_all();
              *pixel = 
                ((int)(r) & 0xFF) << 16 | 
                ((int)(g) & 0xFF) << 8  |
                ((int)(b) & 0xFF) | 
                ((int)(a) & 0xFF) << 24; 
                ++pixel;
                ++x;

                if (x == width){
                  x = 0;
                  --y;
                }
            }
            free(copy);
    "
    open("1.txt", "w" ) do |f| f.write  compile(name.to_s, eachpixel) end
    inline do |builder|
        builder.c_raw compile(name.to_s, eachpixel)
    end
    
  end
  
  def instance_do(type = :pixel, lb = nil, &bl)
    (class << self; self; end).send :"define_#{type}_method",  :__temp__, lb, &bl
    send :__temp__
  end
  
  
  
end

class CPPVar
  
  def set(io, a)
    io << "#{self} = #{a};\n"
  end
  
  def get(a)
    "#{self}"
  end
  
  def initialize(text, rev = false)
    @text = text
    @rev = rev
  end
  
  def to_s
    @text
  end
  
  def call(*a)
    CPPVar.new("#{self}(#{a.map(&:to_s).join(",")})")
  end
  
  
  def ^(b)
    CPPVar.new("(#{self}^#{b})")
  end
  
  def +(b)
    if @rev
      CPPVar.new("((#{b})+#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}+(#{b}))")
    end
    
  end
  
   
  def -(b)
    if @rev
      CPPVar.new("((#{b})-#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}-(#{b}))")
    end
  end
  
  
   
  def *(b)
   if @rev
      CPPVar.new("(#{b}*#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}*(#{b}))")
    end
  end
  
  def /(b)
    if @rev
      CPPVar.new("(#{b}/#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}/(#{b}))")
    end
  end
  
  def &(b)
    if @rev
      CPPVar.new("(#{b} && #{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s} && (#{b}))")
    end
  end
  
  def to_i
    CPPVar.new("(int)(#{self.to_s})")
  end
  def |(b)
    if @rev
      CPPVar.new("(#{b} || #{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s} || (#{b}))")
    end
  end
  
  def /(b)
    if @rev
      CPPVar.new("(#{b}/#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}/(#{b}))")
    end
  end
  
  def coerce(fixnum)
    [CPPVar.new(self, true), fixnum]
  end
  
  [:>, :<, :>=, :<=, :==, :%].each{|op|
    define_method op do |b|
    if @rev
      CPPVar.new("((#{b})#{op}#{self.to_s})")  
    else
      CPPVar.new("(#{self.to_s}#{op}(#{b}))")
    end
  end
  
  
  }
end
