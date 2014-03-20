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
    @stdout.write to_mb(to_wc(a+"\0")+"\0\0", @consolecp)
    @stdout.flush
  end
  
  def puts(*a)
    a.each{|x| @stdout.puts to_mb(to_wc(x.to_s + "\0\0"), @consolecp)+"\0"}
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
    @console.printf ">"
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


module Ref
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
  include Ref
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