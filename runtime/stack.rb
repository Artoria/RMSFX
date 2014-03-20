#coding: UTF-8

class RuntimeStack
  def initialize
    @arr = []
  end
  def push(*a)
    @arr.concat a
    self
  end
  def pop(n = 1)
     n = 0 if n > @arr.size
     u = @arr[-n..-1]
     @arr[-n..-1] = []
     u      
  end
  def last
   @arr[-1]
  end
  alias top last
  def stack_eval(str)
     push instance_eval str.gsub(/\{\{(-?\d+)\}\}/){
       "@arr[#{$1}]"
     }
  end
  require 's20'
  def push_str(mem_str)
    push Seiran20.readstr(mem_str)
  end

  def push_wstr(mem_wstr)
    push Seiran20.readwstr(mem_wstr)
  end

  def push_buf(mem, size)
    push Seiran20.readmem(mem, size)
  end

  def push_pack(mem, pack)
    w = ([0]*pack.size).pack(pack).size
    push *Seiran20.readmem(mem, w).unpack(pack)
  end

  def push_cfunc(addr)
    push Seiran20.callproc(addr)
  end

  def push_stdfunc(addr)
    push Seiran20.callproc(addr, :stdcall)
  end

  def push_api(a, b)
    push Seiran20.api(a, b)
  end

  def push_hglobal_wstr(a) # dotnet
    push Seiran20.readwstr(Seiran20.api('Kernel32', 'GlobalLock').call(a))
    Seiran20.api('Kernel32', 'GlobalUnlock').call(a)
  end

  def push_hglobal_wstr_utf8(a) # dotnet
    push Seiran20.to_mb(Seiran20.readwstr(Seiran20.api('Kernel32', 'GlobalLock').call(a))+"\0\0").chomp("\0")
    Seiran20.api('Kernel32', 'GlobalUnlock').call(a)
  end

  def push_sym_wstr(a)
    push Seiran20.readwstr(a).to_sym
  end

  def push_sym_str(a)
    push Seiran20.readstr(a).to_sym
  end
 
  def push_true
    push true
  end

  def push_false
    push false
  end

  def push_nil
    push nil
  end

  def push_ref(id)
    push ObjectSpace._id2ref(id)
  end

  def push_capi(a, b)
    push Seiran20.capi(a, b)
  end

  def push_block(a = nil, &b)
    push b || a
  end
  
end 

