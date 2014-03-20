feature_only :VA

class HookPoint
  
  SETTRACEFUNC = []
  
  def initialize(&b)
    instance_exec &b if b
  end
  
  def push_trace(proc)
    SETTRACEFUNC << proc.to_proc
    set_trace_func SETTRACEFUNC[-1]
  end
  
  def pop_trace
    SETTRACEFUNC.pop
    set_trace_func SETTRACEFUNC[-1]
  end
  
  def go(&b)
    push_trace method(:trace)
    b.call
    pop_trace
  end
  
  def trace *e
    event, file, line, id, binding, classname = e
    event.tr!('-', '_')
    send *e if respond_to?(event)
  end
  
end

alias myrgssmain rgss_main

def find_method(a, b)
  a.ancestors.each{|x|
    return [x, b] if x.instance_methods(false).include?(b)
  }
  return [nil, nil]
end

def rgss_main
  myrgssmain{
    $h = HookPoint.new{
      
      @break_on_enter = {}
      @disable = {}
      
      def call_console(binding)
        require 'C:/RMSFX/rmsfx'
        require 'gameconsole'
        cd binding
      end
      
      def break_on(a, b)
        @break_on_enter[[a,b]] = 1
      end
      
      def break_off(a, b)
        @break_on_enter.delete [a,b]
      end
      

      def call(file, line, id, binding, klass)
        if @break_on_enter[[klass, id]]
          STDOUT.puts "breakpoint on #{klass} #{id} for #{eval('self', binding)}"
          call_console(binding)
        end
      end
      
      alias c_call call
      break_on Scene_Base, :main
      
    }
    
    $h.go{ 
      yield
    }
  }
end
