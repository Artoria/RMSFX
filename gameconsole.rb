
#fun and tears with coding:UTF-8

module Seiran20
  module_function
  class ::Integer; def to_ptr; self; end; def to_param; 'i'; end; def ord; self; end; end
  class ::String;def to_ptr; [self].pack('p').unpack('L').first; end; def to_param; 'p'; end; end
  
  def procname(a, b)
    class << a; self; end.send :define_method, :inspect do b end
    a
  end

  def api(dll,func)
    procname lambda{|*args|
       Win32API.new(dll,func,args.map{|x|x.to_param}, 'i').call *args
    }, "Seiran20.api<#{dll}!#{func}>"
  end

  LL = api("kernel32", "LoadLibrary")
  GPA = api("kernel32", "GetProcAddress")
  def funcaddr(dll, func)
     x = GPA.call(LL.call(dll), func)
     x == 0 ? nil : x
  end
  def capi(dll, func)
     callproc(GPA.call(LL.call(dll), func))
      procname lambda{|*args|apicall.call((code=[0x55,0xe589].pack('CS')+args.map{|x| [0x68, x.to_ptr].pack('CL')}.reverse.join+[0xb8, addr.to_ptr, 0xD0FF, 0xc481, (stdcall ? 0 : args.length*4) , 0x10c2c9].pack('CLSSLL')),0,0,0,0)}, "Seiran20.capi<#{dll}!#{func}>"
  end

    def to_wc(str, cp = 65001)
    (buf = "\0\0"*str.length)[0, 2*api('Kernel32', 'MultiByteToWideChar').call(cp, 0, str.to_ptr, -1, buf, buf.length)]
  end
  
  def to_mb(str, cp = 65001)
    (buf = "\0\0"* str.length)[0, api('Kernel32', 'WideCharToMultiByte').call(cp, 0, str.to_ptr, -1, buf, buf.length, 0, 0)]
  end

end
class Console
  include Seiran20
  def initialize
    api('Kernel32', 'AllocConsole').call
    @hin  = api('kernel32', 'GetStdHandle').call(-10)
    @hout = api('kernel32', 'GetStdHandle').call(-11)
    @w = api('Kernel32', 'GetConsoleWindow').call
    api('user32', 'ShowWindow').call @w, 5
    @stdin  = File.open("CONIN$", "r")
    @stdout = File.open("CONOUT$", "w")
    @stderr = File.open("CONOUT$", "w")
    @consolecp = 936
  end
  
  def write(a)
    @stdout.write to_mb(to_wc(a.to_s + "\0"), @consolecp)
    @stdout.flush
  end
  
  # fixed for RMVA
  # thank Sion @ 66rpg
  # http://bbs.66rpg.com/forum.php?mod=redirect&goto=findpost&ptid=343335&pid=2395564
  def translate(a)
    if a.respond_to?(:force_encoding)
      a.force_encoding("UTF-8")
    else
       to_mb(to_wc(a.to_s + "\0"), @consolecp)
    end
  end
  
  def puts(*a)
    a.each{|x| @stdout.puts translate(x)}
    @stdout.flush
  end

  def read(*a)
    @stdin.read(*a)
  end
  
  def gets
    @stdin.gets
  end
  
  def printf *a
    @stdout.printf *a
    @stdout.flush
  end
  
  def fontcolor=(color)
    api('Kernel32', 'SetConsoleTextAttribute').call @hin, transcolor(color)
    api('Kernel32', 'SetConsoleTextAttribute').call @hout, transcolor(color)
  end
  
  def title=(title)
    api('Kernel32', 'SetConsoleTitle').call title
  end
  
  def cursorheight=(a, b = 1)
    api('Kernel32', 'SetConsoleCursorInfo').call @hout, [a, b].pack("LL")
  end

  def move(x, y, w, h)
    api('Kernel32', 'SetConsoleWindowInfo').call @hout, 1, [x, y, x+w, y+h].pack("S*")
  end
  
  private
  def transcolor(color)
    a = color.alpha >= 128 ? 8 : 0
    r = color.red   >= 128 ? 4 : 0
    g = color.green >= 128 ? 2 : 0
    b = color.blue  >= 128 ? 1 : 0
    a | r | g | b
  end
end

class Reset < Exception
end
class Hangup < Exception
end


class GameConsole
  class Void
  end
  Active = []
  def initialize(obj = TOPLEVEL_BINDING, title = "Main Console", eval = nil)
    @console = Console.new    
    unless obj.is_a?(Binding)
      obj = obj.instance_eval{Object.instance_method(:binding).bind(self).call}
    end
    @console.title = title || "Main Console"
    @binding = obj
    if eval
      @eval = eval
    else
      @eval = self
    end
    show_banner
  end
  
  def eval(*a)
    method_eval = @eval.method(:eval)
    if method_eval != method(:eval)
      method_eval.call *a
    else
      super
    end
    ensure
      $@.shift if $@
  end
  
  def show_banner
    banner
    s = eval('self', @binding)
    @text = s.gc_s rescue s.to_s rescue nil
    @console.puts " *** #{@text} ***"
  end
  
  def banner
    @console.fontcolor = Color.new(255,255,255,0)
  end
  
  def prompt
    @console.fontcolor = Color.new(0,0,255,128)
    @console.printf "> "
  end
  
  def getinput
      @console.fontcolor = Color.new(255,255,255,128)
      @input = @console.gets
  end
  
  def result
    @console.fontcolor = Color.new(0,255,255,255)
    @console.puts @result.inspect
  end
  
  def warning(text = nil)
    @console.fontcolor = Color.new(255,0,255,0)
    @console.puts text.inspect if text
  end
  
  def error(text = nil)
    @console.fontcolor = Color.new(255,0,255,1)
    @console.puts text.inspect if text
  end
    
  def preinput
      @state = :postinput
      prompt
      getinput
  end
  
  def postinput  
      @state = :preinput
      @result = eval @input, @binding, "<Console #{@text}>", 1
      result unless GameConsole::Void === @result
    rescue SystemExit => ex
      raise ex
    rescue ::Hangup => ex
      raise ex
    rescue ::Reset => ex
      raise ex
    rescue Object => ex
      error
           @console.puts $!.inspect
           @console.puts $!.to_s
           @console.puts *($!.backtrace)
           GameConsole::Void
    
  end
  
  
  def go
    Active.push self
    @state = :preinput
    while true
      begin
        preinput
        postinput
      rescue SystemExit
        break
      rescue ::Reset
        warning
           @console.puts "System Reset Captured"
      rescue ::Hangup
        warning
           @console.puts "System Hangup Captured(RMXP?)"
           postinput
      end
    end
    Active.pop
    nil
  end
end

class Object
  def cd(obj, eval = nil)
    GameConsole.new(obj, nil, eval).go 
    GameConsole::Active[-1].show_banner if GameConsole::Active[-1]
    GameConsole::Void.new
    ensure
      $@.shift if $@
  end
  def stdin
    GameConsole::Active[-1].stdin
  end
  def stdout
    GameConsole::Active[-1].stdout
  end
  def stderr
    GameConsole::Active[-1].stderr
  end
end


module Ref_
  module_function
  class Ref
    def initialize(a, b)
      @getter = a
      @setter = b
    end
    def [](*a)
      @getter.call(*a)
    end
    def []=(*a)
      @setter.call(*a)
    end
    alias value  []
    alias value= []=
  end
  
  public
  def globalref(str)
    getter = eval("proc{ eval(gv_lookup(#{str.inspect})) } ")
    setter = eval("proc{|a| x = gv_lookup(#{str.inspect}); eval(\"\#{x} = a\");}")
    Ref.new(getter, setter)
  end
  
  def gv_lookup(gv)
    if gv =~ /(.*?)\\(\d+)/
      beginwith, len = $1, $2.to_i + 1
      global_variables.map{|x|x.to_s}.find{|x| x.length == len && x.index(beginwith) == 0}
    else
      gv
    end
  end
  
  def iv_lookup(iv)
    if iv =~ /(.*?)\\(\d+)/
      beginwith, len = $1, $2.to_i + 1
      instance_variables.map{|x|x.to_s}.find{|x| x.length == len && x.index(beginwith) == 0}
    else
      iv
    end
  end
  
  def ivarref(str)
    getter = eval("proc{ instance_variable_get(iv_lookup(#{str.inspect})) } ")
    setter = eval("proc{|a| instance_variable_set(iv_lookup(#{str.inspect}), a) }")
    Ref.new(getter, setter)
  end
end

class Object
  include Ref_
end

class Lancet
  IDENTX = /[A-Za-z_][A-Za-z0-9_]*[?!=]?/
  IDENT = /[A-Za-z_][A-Za-z0-9_]*/
  IDENTA = /[A-Za-z_][A-Za-z0-9_]*[?!=]?(\\(\d+))?/
  
  def transform(str)
    str.gsub!(/\$#{IDENTA}/){ "globalref(#{$&.inspect}).value" }
    str.gsub!(/\@#{IDENTA}/){ "ivarref(#{$&.inspect}).value" }
       
    str
  end
  def eval(str, *a)
    super(transform(str), *a)
  end
end

class << Input
  alias gcupdate update
  def update
    gcupdate
    if trigger?(self::F5)
      if press?(self::CTRL)
        cd eval('self', TOPLEVEL_BINDING)
      else
        Thread.new do cd eval('self', TOPLEVEL_BINDING) end
      end
    end
  end
end