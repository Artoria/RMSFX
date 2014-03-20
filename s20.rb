module Seiran20
  module_function
  class ::Integer; def to_ptr; self; end; def to_param; 'i'; end; def ord; self; end; end
  class ::String;def to_ptr; [self].pack('p').unpack('L').first; end; def to_param; 'p'; end; end
    

  def api(dll,func)
    lambda{|*args|
       Win32API.new(dll,func,args.map{|x|x.to_param}, 'i').call *args
    }
  end

  
  def callproc(addr, type = :cdecl)
    stdcall = type == :stdcall
    raise "addr == 0 " if addr.to_ptr == 0
    apicall = api('user32', 'CallWindowProcW')
    lambda{|*args|apicall.call((code=[0x55,0xe589].pack('CS')+args.map{|x| [0x68, x.to_ptr].pack('CL')}.reverse.join+[0xb8, addr.to_ptr, 0xD0FF, 0xc481, (stdcall ? 0 : args.length*4) , 0x10c2c9].pack('CLSSLL')),0,0,0,0)}
  end

  LL  = api("kernel32", "LoadLibrary")
  GPA = api("kernel32", "GetProcAddress")
  def funcaddr(dll, func)
     x = GPA.call(LL.call(dll), func)
     x == 0 ? nil : x
  end
  def capi(dll, func)
     callproc(GPA.call(LL.call(dll), func))
  end

  ASCIICHAR = [0].pack('C') #avoid RMVA encoding problems
  def findRGSS     
     process = Seiran20.api('Kernel32','GetCurrentProcess').call
     num = "\0"*4
     epm = Seiran20.api('psapi', 'EnumProcessModules')
     epm.call process, 0, 0, num
     num = num.unpack('L')[0]
     x = "\0"*(num*8)
     lnum = "\0"*4
     epm.call process, x, num, lnum
     gmf = Seiran20.api('kernel32', 'GetModuleFileName')
     x = x.unpack('L*')
     x.each{|xx|
     	buf = ASCIICHAR * 1024     #avoid RMVA encoding problems
     	gmf.call xx, buf, 1024
     	buf = buf.gsub(/\0.+$/){}
     	r = File.basename(buf)
     	if Seiran20::GPA.call(xx, "RGSSEval")!=0
                return [buf, xx]
        end
     }
     ['', 0]
  end
  ID_RGSS, RGSS = findRGSS
  
  def readmodule(name)
    api('psapi', 'GetModuleInformation').call(api('kernel32', 'GetCurrentProcess').call,handle=api('kernel32', 'GetModuleHandle').call(name),info = "\0"*12,12)
    api('kernel32', 'RtlMoveMemory').call(buf = "\0"*info[4, 4].unpack('L').first, info[0, 4].unpack('L').first, buf.length)
    [buf, handle]
  end

  def readmem(start, len)
    api('kernel32', 'RtlMoveMemory').call buf = "\0"*len, start, len
    buf
  end
  
  def writemem(start, len, value)
    api('kernel32', 'RtlMoveMemory').call start, value, [len, value.length].min
  end
    
  private
  module_function
  def findcall(_4, _5, a, b, t)
    _1, k  = [], -1;  _1.push(k) while k = _4.index("#{a}\0", k+1)
    _2, k  = [], -1;  _2.push(k) while k = _4.index("#{b}\0", k+1)
    _3 = [];   
    _1.each{|x|  k=-1; _3.push(-k)  while k = _4.index([0x68, _5+x].pack('CL'), k+1)}
    _2.each{|x| k=-1; _3.push(k)   while  k = _4.index([0x68, _5+x].pack('CL'), k+1)}  
    _6, _7 = [0, 0], 1.0/0
    _3 = _3.sort_by{|x| x.abs}
    (_3.length-1).times{|l|
         next if _3[l] > 0 or _3[l+1] < 0
         q = _3[l+1] + _3[l]
         if _7 > q
           _7 = q
           _6 = l
         end
    } 
    r = _3[_6+1]
    t.times do
      r+=1 while _4[r].ord != 0xe8
      r+=1
    end
    r+=1 while _4[r].ord != 0xe8
    _4[r+1, 4].unpack('L').first + r + _5 + 5
  end

  def rgssx_increment
    text,handle = readmodule(ID_RGSS)
    text = text.unpack('C*').pack('C*')
    [
     rb_define_method = findcall(text, handle, 'Bitmap', 'initialize', 0),
     rb_intern        = findcall(text, handle, 'Marshal', 'dump', 0),
     rb_funcall       = findcall(text, handle, 'Marshal', 'dump', 1),
    ]
  end
  if ID_RGSS != '' and !$NO_RGSSX
     RGSSX = rgssx_increment unless constants.include?(:RGSSX)
     ID_CALL = callproc(RGSSX[1]).call "call"
  end
  class Internal_Callback
    attr_accessor :block, :code
    def to_int() code.to_ptr end
    def to_param() 'i' end
    def to_str() code end
    def to_ptr() to_int() end
  end
  
  public 
  module_function
  def callback(type = :stdcall, &block)
    stdcall = type == :stdcall
    x = Internal_Callback.new
    ar = block.arity
    if ar != -1
      x.block = lambda{|ebp|block.call readmem(ebp+8, ar*4).unpack('L*')}
    else
      x.block = block
    end
    x.code  = [0x55e58955, 0x40e0d158, 0x50,
               0x68, 0x00000001, 
               0x68, ID_CALL, 
               0x68, x.block.object_id*2, 
               0xb8, RGSSX[2],
               0xc481d0ff,  0x00000010,
               0xc2c9f8d1, stdcall ? ar * 4 : 0 ].pack('LLCCLCLCLCLLLLS')
    x
  end
  
  def thiscall(this, addr, convention = :stdcall, type = :vc)
    stdcall = convention == :stdcall
    vc     = type == :vc
    raise "addr == 0 " if addr.to_ptr == 0
    code=[0x55,0xe589].pack('CS')
    code1 = code
    code2 = ""
    if vc
       code2 += [0x51, 0xB9, this.to_ptr].pack('CCL')
    else
       code2 += [0x68, this.to_ptr].pack('CL')
    end
    code2 += [0xb8, addr.to_ptr, 0xC481D0FF].pack('CLL')
    code3 = [0x59].pack('C') if vc
    code3 += [0x10c2c9].pack('L')
    apicall = api('user32', 'CallWindowProcA')
    lambda{|*args|
    apicall.call(
       code1+args.map{|x| [0x68, x.to_ptr].pack('CL')}.reverse.join+code2+[(stdcall ? 0 : args.length*4) + (stdcall ? 0 : (vc ? 0 : 4))].pack('L')+code3,0,0,0,0
     )
    } 
  end
  
  
  def to_wc(str, cp = 65001)
    (buf = "\0\0"*str.length)[0, 2*api('Kernel32', 'MultiByteToWideChar').call(cp, 0, str.to_ptr, -1, buf, buf.length)]
  end
  
  def to_mb(str, cp = 65001)
    (buf = "\0\0"* str.length)[0, api('Kernel32', 'WideCharToMultiByte').call(cp, 0, str.to_ptr, -1, buf, buf.length, 0, 0)]
  end
    

   def urlread(url)
       api('urlmon', 'URLDownloadToCacheFile').call(0, url, buf="\0"*1024, 1024, 0, 0)
       open(buf.sub(/\0+$/){}, 'rb'){|f| f.read}
   end
  
   def new_optheader(text)
       text.unpack('SCCLLLLLLLLLSSSSSSLLLLSSL*')
   end
   
   def new_section(text)
       arr = text.unpack('a8LLLLLLSSL')
       arr[0].sub!(/\0.*$/){}
       arr
   end
   
   def new_dir(text)
       text.unpack('LL')
   end
   
   MEM = api('Kernel32', 'RtlMoveMemory')
   LL  = api('Kernel32', 'LoadLibrary')
   GPA = api('Kernel32', 'GetProcAddress')
   SL  = api('Kernel32', 'lstrlenA')
   WSL  = api('Kernel32', 'lstrlenW')
   def lock(mem) api('Kernel32', 'GlobalLock').call mem end
   def unlock(mem) api('Kernel32', 'GlobalUnlock').call mem end
   def allocmovable(num) api('Kernel32', 'GlobalAlloc').call 0x2000, num end
   def alloc(num) api('Kernel32', 'GlobalAlloc').call 0, num end
   def free(addr)  api('Kernel32', 'GlobalFree').call addr  end
   def copy(addr1, addr2, num)  MEM.call addr1, addr2, num end
   def mem_readint(addr1) buf="1234"; MEM.call(buf, addr1, 4); end;
   def mem_writeint(addr1, num); MEM.call(addr1, [num].pack('L'), 4);end
   def addrof(handle, name) ; GPA.call(LL.call(handle), name); end
   def readstr(x) readmem(x, SL.call(x)); end;
   def readwstr(x) readmem(x, WSL.call(x)*2); end;
   private :new_section, :new_optheader, :new_dir
   def peldr(dll, init = true)
       doshdr = dll[0, 60].unpack('S*') + dll[60, 4].unpack('L*')
       signature = dll[60, 4].unpack('L').first       
       return if dll[signature, 2] != "PE"
       newhdr    = dll[newhdrofs = signature+4, 20].unpack('SSLLLSS')
       optheader = new_optheader dll[opthdrofs = newhdrofs+20, newhdr[5]]
       secs,dirs ={}, []
       entry, imagesize, codebase, database, imagebase = optheader[6], optheader[19], optheader[7], optheader[8], optheader[9]
       dll = dll + "\0\0" * (imagesize - dll.length)
       image     = api('Kernel32', 'VirtualAlloc').call(0, imagesize*2, 0x1000, 0x40)
       sechdrofs = opthdrofs + newhdr[5]
       newhdr[1].times{|x|arr=new_section(dll[sechdrofs + x*40, 40]); secs[arr[0]]=arr}
       optheader[29].times{|x|dirs.push new_dir(dll[opthdrofs+96+x*8, 8])}
       addr = dll.to_ptr
       r = 0
       secs.each{|k, x| copy(x[2] + image, x[4] + addr, x[1])}       
       if secs[".reloc"]
         relocdata = dll[secs[".reloc"][4], secs[".reloc"][1]]
         ptr, r, len = 0, [], relocdata.length
         off =  image - imagebase       
         while ptr < len
           st, le = relocdata[ptr, 8].unpack('LL')
           data = relocdata[ptr += 8, le - 8].unpack('S*')
           data.select{|x|x&0xF000 == 0x3000 }.each{|x|
                 addr = st+(x&0xFFF); 
                 next if addr >= imagesize
                 mem_writeint(image+addr,off+readmem(image + addr, 4).unpack('V').first)
           }
           ptr += le - 8
         end
       end
       import  = readmem(image + dirs[1][0], len = dirs[1][1])
       imports = {}
       ptr = 0
       while ptr < len
         pint, time, fw, dl, ft = import[ptr, 20].unpack('L*')
         break if ft == 0
         next if ft > imagesize
         dlname = readstr(dl + image)
         imports[dlname] ||= {}
         piat = ft + image
         pint += image
         while true
            fn    = readmem(piat,4).unpack('L').first
            aaddr = readmem(pint,4).unpack('L').first
            break if fn == 0
            imports[dlname][str = readstr(aaddr + image + 2)] = piat
            str1 = readstr(aaddr + image + 2)
            str1 = nil if str1 == ""
            ord = readmem(aaddr + image, 2).unpack('S').first
            addr = addrof(dlname, str || ord)
            p "#{dlname}.#{str}/#{ord}" if addr == 0
            writemem(piat, 4, [addr].pack('L'))
            piat += 4; pint += 4
         end 
         ptr += 20
       end

       exp = readmem(image + dirs[0][0] ,len = dirs[0][1])
       export = exp.unpack('LLSSLLLLLLL')
       name = readstr(export[4] + image)
       ef, en = export[6], export[7]
       eat,ent,eot = export[8], export[9], export[10]
       eat = readmem(eat + image, ef * 4).unpack('L*').map{|x| x+image}
       ent = readmem(ent + image, en * 4).unpack('L*').map{|x| 
            if x <= imagesize
              readstr(x+image)
           end
      }
       eot = readmem(eot + image, en * 2).unpack('S*')
       names = {}
       eat.each_index{|x|names[ent[x]] = eat[eot[x]]}
       export = [eat, ent, eot, names]
       callproc(image + entry, :stdcall).call image,1,1  if init 
       { :image => image, :entry => entry, :imagesize => imagesize, :imports => imports, :exp_name => name, :exp_func => names}
     end
     
     
     def hwnd
          msg , r, pm, ac = "\0"*24, 0, api('user32', 'PeekMessage'), api('user32', 'GetAncestor')
          loop do
            return r if pm.call(msg, 0, 0, 0, 0) != 0 and ((r = ac.call(msg.unpack('L').first, 3))!=0)
            ::Graphics.update if defined?(::Graphics)
         end
     end
    
     
    
     def read_cbtext
          h = api('User32', 'OpenClipboard').call hwnd
          raise "Clipboard already open" if h == 0
          hgl = api('User32', 'GetClipboardData').call 13
          r = lock(hgl)
          ret = readwstr(r)
          unlock(hgl)
          api('User32', 'CloseClipboard').call
          to_mb(ret+"\0\0").chop
     end
        
     def clipformats
       a, r, ecf = [], 0, api('User32', 'EnumClipboardFormats')
       loop do
          r = ecf.call(r)
          if r != 0
            a.push(r)
          else
            break
          end
        end
        a
     end
     
     def read_rawdata 
      h = api('User32', 'OpenClipboard').call hwnd
      raise "Clipboard already open" if h == 0
      begin
       gn = api('User32', 'GetClipboardFormatName')
       a = clipformats       
       n = a.map{|x| buf = "\0"*1024; gn.call(x, buf, 1024); buf.gsub(/\0+$/){}}
       n.each_with_index{|x, i|
         if yield(x)
                 hgl = api('User32', 'GetClipboardData').call a[i]
                 r = lock(hgl)
                 t0 = api('Kernel32', 'GlobalSize').call(r)
                 ret = readmem(r, t0)
                 unlock(hgl)
                 return ret
         end
       }
      ensure
        api('User32', 'CloseClipboard').call
      end
       
    end
    
     private :read_rawdata
     def read_editordata
       ret = read_rawdata{|x|
         x[/RPG/] or x[/VX Ace/] 
       }
       ret.slice!(0, 4)
       Marshal.load(ret)
     end     
     
     
     SendMsg = lambda{|sender, receiver, methodname, argc, *args|
       receiver.send methodname, *args
     }
     
     MODULES = {}
     FNS = {}
     
     class Intern_Class_Class
        def new(*args)
           x = Intern_Class.new
           x.instance_variable_set :@klass, self
           x.instance_variable_set :@ptr, self.constructor(*args)
           x
        end
     end
     
     class Intern_Class
        def method_missing(sym, *args)
          (class << self; self; end).send :define_method, sym, lambda{|*a|
              @klass.send sym, @ptr, *ar
          }
          send sym, *args
        end
     end
      
     def loadmodule(name, alis = nil)
       r = MODULES[alis ||= name]
       return r if r       
       defn = callproc(RGSSX[0]) 
       calladdr = callproc(GPA.call(LL.call(name), 'InitModule'))
       this = MODULES[alis] = Intern_Class_Class.new
       FNS[alis] = []
       selfobj    =  (class << this;object_id*2; end)
       selfclass  =  this.object_id*2
       fn1 = callback{|name, addr|defn.call(selfobj, name, addr, -1)}
       sendmsg = callback{|receiver, methodname, argc, args|
         recv  = readstr receiver
         mname = readstr methodname
         arg   = readmem(args, argc*4).unpack('L*')
         SendMsg.call this, MODULES[recv], mname, argc, *arg
       }
       FNS[alis].push fn1
       FNS[alis].push sendmsg
       calladdr.call(fn1, sendmsg)
       MODULES[alis]
     end


     def lm(name)
       loadmodule("C:/RMSFX/lib/#{name}.mod", name)
     end
end
