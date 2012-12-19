require 'ext'
require 'libpng'
class OpenGL < ExternalWrapper
  PFD = "28000100250000000020000000000000000000000000002008000000000000000000000000000000"
  def self.init
    self.const_set :GL, find("opengl32.dll")
    self.const_set :GLU, find("glu32.dll")
    @const = File.read("C:/RMSFX/include/gl.h")
    @constants = Hash.new{|h, k| h[k.to_s] = k.to_s}
    @const.gsub(/^#define\s+(\S+)\s+(\S+)/){
        @constants[$1] = $2
    }
    Graphics.update
    USER32.SetWindowLong(Seiran20.hwnd, -16, USER32.GetWindowLong(Seiran20.hwnd, -16) | 0x6000000)
    @hwnd = USER32.CreateWindowEx(0, "Button", "Hello", 0x56000000, 0, 0, 320, 240, Seiran20.hwnd, 0, 0, 0)
#USER32.SetWindowLong(@hwnd, -16, Seiran20.funcaddr('user32', 'DefWindowProcA'))
    @hdc  = USER32.GetDC @hwnd
    @pf   = GDI32.ChoosePixelFormat(@hdc, PFD)
    raise "error ChoosePixelFormat" if @pf == 0
    raise "error SetPixelFormat" if 0 == GDI32.SetPixelFormat(@hdc, @pf, PFD)
    @hrc = self[:wglCreateContext].call @hdc
    raise "error wglCreateContext" if 0 == @hrc
  end
  
  def self.setcurrent
        raise "OpenGL.scene" if 0 == self[:wglMakeCurrent].call(@hdc, @hrc)
  end
  def self.scene
    raise "OpenGL.scene" if 0 == self[:wglMakeCurrent].call(@hdc, @hrc)
    yield if block_given?
    OpenGL::GDI32.SwapBuffers()
  end
  
  def self.translate(text, neg = false)
    if text =~ /([\d\.]+)f?/ 
       k = $1
       if k.index(".")
          return [neg ? -Float(k) : Float(k)].pack("F").unpack("l").first 
       end
    end
    text
  end

  def self.save_to_bitmap(bitmap)
    width  = bitmap.width
    height = bitmap.height
    addr   = Libpng.ptr(bitmap)
    hDIB     = KERNEL32.GlobalAlloc(0, width*height*4)
    lpBitmap = KERNEL32.GlobalLock(hDIB)
    bi       = [40, width, height, 1, 32, 0, width*height*4, 0, 0, 0, 0].pack("L*")

    GDI32.GetDIBits(@hdc, @hbitmap, 0, height, lpBitmap,  bi,  0)
    Seiran20.writemem(addr, width*height*4, hDIB)
    KERNEL32.GlobalUnlock(hDIB)
    KERNEL32.GlobalFree(hDIB)
  end
  def self.compile(text)
     text.gsub(/(?<![\$@]])([a-z][A-Za-z0-9]+\s*)\(/){"self[:#{$1}].call("}.gsub(/-[0-9]+\.[0-9]+[A-Za-z]?/){translate($&, true)}.gsub(/[0-9]+\.[0-9]+[A-Za-z]?/){translate($&)}.gsub(/[A-Z0-9_]+/){@constants[$&] || $&}.gsub(/\/\//){"#"}
  end


  def self.[](a)
        if a.to_s[/^glu/]
          CACHE[a] ||= Seiran20.capi(self.const_get(:GLU), a.to_s)
        else
          CACHE[a] ||= Seiran20.capi(self.const_get(:GL), a.to_s)
        end
  end

  init
end



