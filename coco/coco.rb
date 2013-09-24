=begin
# 
# Created by Hana Seiran 
#
# Documentation by Hana Seiran
#

Lisense:

Copyright (c) 2012, Seiran
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
   This product includes software developed by Seiran.

THIS SOFTWARE IS PROVIDED BY Seiran ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Seiran BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end


module CocoSimple
end

class CocoNameSpace
        def initialize(text, sep = "/")
                @text = text
                @sep  = sep
        end

        def to_s
                @text
        end

        def to_str
                @text
        end

        def method_missing(sym, *args)
                CocoNameSpace.new(@text + @sep + sym.to_s, @sep)
        end
end

def coco
        CocoNameSpace.new('coco')
end

$coco_info = []


def info(title)
        t = Time.now
        yield
        r = Time.now - t
        $coco_info << sprintf("%10s boots in %2.6fs", title, r)
end

module CocoSimple
        class API
            def initialize(dll)
                @dll = dll
            end
            def method_missing(sym, *args)
                params = args.map{|x| x.is_a?(String) ? 'p' : 'L'}.join
                Win32API.new(@dll, sym.to_s, params, 'i').call *args
            end
        end

        class DLL < API
          Kernel32 = API.new('kernel32')    
          def initialize(dll)
            @dll = dll
            @handle = Kernel32.LoadLibrary(@dll)
          end
          def [](name)
            x = Kernel32.GetProcAddress(@handle, name)
            return nil if x == 0
            x
          end
        end
end

info 'X'  do require 'Coco/X' end
module CocoSimple
        class JIT
          User32 = API.new('user32')
          Kernel32 = API.new('kernel32')
          def initialize
            clear
          end
          
          def clear
            @code = ""
          end
          
          def codebegin 
            @code << [0x55, 0x89, 0xe5].pack('C*')
          end
          
          def codeend
            @code << [0xc9, 0xc2, 0x10, 0x00].pack('C*')
          end
          
          def call
            Kernel32.FlushInstructionCache Kernel32.GetCurrentProcess, @code, @code.length
            User32.CallWindowProc @code, 0, 0, 0, 0
          end

          def cdeclcall(addr, *args)
            args.map!{|x| x.is_a?(String) ? [x].pack('p').unpack('L')[0] : x}
            args.reverse!
            @code << args.inject(""){|x, y|  
              x << [0x68, y].pack('CL')                      #依次把反向参数压栈
            } << [0xb8, addr].pack('CL') <<                   #mov eax, addr
                [0xFF, 0xD0].pack('CC') <<                 #call eax 这两行调用addr处的函数
                [0x83, 0xc4, args.length * 4].pack('C*') #平衡堆栈, 参数个数 * 4个字节
          end

          def stdcall(addr, *args)
            args.map!{|x| x.is_a?(String) ? [x].pack('p').unpack('L')[0] : x}
            args.reverse!
            @code << args.inject(""){|x, y|  
              x << [0x68, y].pack('CL')                      #依次把反向参数压栈
            } << [0xb8, addr].pack('CL') <<                   #mov eax, addr
                [0xFF, 0xD0].pack('CC')
          end
        end


        code = "55 8B EC 60 B8 00 00 00 00 0F A2 8B 45 08 89 18 89 50 04 89 48 08 C6 40 0C 00 61 C9 C3".split(' ').map{|x|[x].pack('H*')}*""
        jit = JIT.new
        buf = "\0"*20
        jit.codebegin
        jit.cdeclcall [code].pack('p').unpack('L').first, buf
        jit.codeend
        jit.call
        $coco_info << ('CPU vendor: ' + buf)
                
        class IntPtr
           KERNEL32 = DLL.new('Kernel32')
           attr_accessor :addr
           alias to_int addr
           def initialize(addr = 0)
                @addr = addr
           end
           def indir(x=0)
                IntPtr.new(self[4].unpack('L').first + x)
           end
           def [](len)
                buf = "\0"*len
                KERNEL32.RtlMoveMemory(buf, self.addr, len)
                buf
           end
           def []=(len, buf)
                KERNEL32.RtlMoveMemory(self.addr, buf, len)
                buf
           end
        end

        class VirTable
                def initialize(obj)
                        @ptr = IntPtr.new(@obj = obj)
                end
                def [](index)
                        @ptr.indir.indir(index*4).indir.addr
                end
        end

        class GUID
                OLE32     = DLL.new('ole32')
                attr_accessor :guid
                alias to_s guid
                def to_i
                        [guid].pack('p').unpack('L').first
                end
                def self.translate(str)
                        str = str.dup
                        str[0, 4] = str[0, 4].reverse
                        str[4, 2] = str[4, 2].reverse
                        str[6, 2] = str[6, 2].reverse
                        str
                end
                def initialize(str)
                        @str  = str
                        @guid = GUID.translate([str.scan(/[0-9A-Fa-f]{2}/).join].pack('H*'))
                end
                def self.CLSIDFromProgID(progid)
                        clsid = "\0"*16
                        if OLE32.CLSIDFromProgID(progid, clsid)!=0
                                raise "CLSIDFromProgID : Can't find #{progid.fromUnicode}"
                        end
                        clsid
                end
        end

        class GUID
                IID_IUnknown    = new('00000000-0000-0000-C000-000000000046').guid
                IID_IDispatch   = new('00020400-0000-0000-C000-000000000046').guid
                IID_NULL        = new('00000000-0000-0000-0000-000000000000').guid
        end

        module COM
                KERNEL32 = DLL.new('Kernel32')
                OLE32     = DLL.new('ole32')
                OLEAUT32 = DLL.new('oleaut32')
                extend self
                def init
                        OLE32.CoInitialize 0
                end
                def fini
                        OLE32.CoUninitialize
                end

        end

        class IUnknown
                extend COM
                KERNEL32 = DLL.new('Kernel32')
                OLE32     = DLL.new('ole32')
                OLEAUT32 = DLL.new('oleaut32')
                CLSCTX_ALL            = 1+2+4+16
                LOCALE_SYSTEM_DEFAULT = 0x0800
                def pthis
                        @ppobj
                end
                def this
                        @pobj
                end
                def __vtable__
                        %w(QueryInterface AddRef Release)
                end
                def COMError(hr, text = "", prefix = "IUnknown")
                        x = (((hr + (1<<32) ) % (1<<32)).to_s(16))
                        raise prefix + "." +  x  + "\n\n" + text + "\n" 
                end
                def self.fromCLSID(clsid, iid = GUID::IID_IUnknown)
                        new(0, 0).instance_eval {
                                @clsid = GUID.translate(clsid).unpack('H*')
                                @lobj  = "\0"*16
                                @ppobj = [@lobj].pack('p').unpack('L').first
                                hr= OLE32.CoCreateInstance(clsid, 0, CLSCTX_ALL, iid, @ppobj)
                                COMError hr if hr!=0
                                @pobj = @lobj.unpack('L').first
                                @vtbl = VirTable.new(@ppobj)
                                self
                        }
                end
                def self.fromProgID(progid, iid = GUID::IID_IUnknown)
                        clsid = GUID.CLSIDFromProgID(progid)
                        self.fromCLSID(clsid, iid).instance_eval{
                                @progid = progid.fromUnicode
                                self
                        }
                end
                def method_missing(sym, *a)
                        if i = self.__vtable__.index(sym.to_s)
                                func = @vtbl[i]
                                (class <<self; self; end).send :define_method, sym, lambda{|*args|
                                        args.map!{|x| x.is_a?(String) ? [x].pack('p').unpack('L')[0] : x}
                                        resrv = @ppobj
                                        jit = JIT.new
                                        jit.codebegin
                                        jit.stdcall func, this, *args
                                        jit.codeend
                                        ret = jit.call                    
                                        if @ppobj != resrv
                                               @pobj = @lobj.unpack('L').first
                                               @vtbl = VirTable.new(@ppobj)
                                        end
                                        ret
                                }
                                send sym, *a
                        else
                                super
                        end
                end
                def dispose
                        Release()
                end
                def as(klass)
                        klass.new(@ppobj, @pobj)
                end
                alias << as
                def initialize(ppobj, pobj)
                        @ppobj = ppobj
                        @pobj  = pobj
                        @vtbl = VirTable.new(@ppobj)
                end
        end

        class IDispatch < IUnknown
              DISPATCH_METHOD         =   1 
              DISPATCH_PROPERTYGET    =   2
              DISPATCH_PROPERTYPUT    =   4
              DISPID_PROPERTYPUT      =  -3
              KERNEL32 = DLL.new('Kernel32')
              OLE32     = DLL.new('ole32')
              OLEAUT32 = DLL.new('oleaut32')

              def __vtable__
                      super + %w(GetTypeInfoCount GetTypeInfo GetIDsOfNames Invoke)
              end
              def [](name)
                      dispids = "\0"*16
                      hr = GetIDsOfNames(GUID::IID_NULL, [name.toUnicode].pack('p'), 1, LOCALE_SYSTEM_DEFAULT, dispids)
                      COMError hr, "GetIDsOfNames[#{name}]", "IDispatch" if hr!=0
                      dispids.unpack('L').first
              end
              def bstrs
                @bstrs ||= []
              end
              def packargs(args)
                      ar = args.map{|x| Variant.from(x, bstrs)}.reverse.join
              end
              def call(name, *args)
                      id   = self[name]
                      ar   = packargs(args)
                      dp   = [ar, 0, args.length, 0].pack('pLLL')
                      result = "\0"*16
                      hr = Invoke(id, GUID::IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD, dp, result, 0, 0)
                      COMError hr, "Invoke[#{name}(#{args})]", "IDispatch" if hr!=0
                      ret = Variant.to(result)
                      Variant.clearBSTR(bstrs)
                      ret
              end
              def put(name, *args)
                      id   = self[name]
                      ar   = packargs(args)
                      dispnamed = [DISPID_PROPERTYPUT].pack('L')
                      dp   = [ar, dispnamed, args.length, 1].pack('ppLL')
                      result = "\0"*16
                      hr = Invoke(id, GUID::IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD | DISPATCH_PROPERTYPUT, dp, result, 0, 0)
                      COMError hr, "Invoke.Put[#{name}(#{args})]", "IDispatch" if hr!=0
                      ret = Variant.to(result)
                      Variant.clearBSTR(bstrs)
                      ret
              end
              def get(name, *args)
                      id   = self[name]
                      ar   = packargs(args)
                      dp   = [ar, 0, args.length, 0].pack('pLLL')
                      result = "\0"*16
                      hr = Invoke(id, GUID::IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD | DISPATCH_PROPERTYGET, dp, result, 0, 0)
                      COMError hr, "Invoke.Get[#{name}(#{args})]", "IDispatch" if hr!=0
                      ret = Variant.to(result)
                      Variant.clearBSTR(bstrs)
                      ret              
              end

              def method_missing(sym, *a)
                case sym.to_s
                        when /(.+)=$/
                                        put $1,*a
                        when /^_(.+)$/
                                get $1,*a
                        else
                                super rescue call sym.to_s, *a
                end
              end
        end

        class CFunc
                def initialize(addr)
                       @addr = addr
                end
                def call *a
                         jit = CocoSimple::JIT.new
                         jit.codebegin
                         jit.cdeclcall @addr, *a
                         jit.codeend
                         jit.call
                end
        end

        class Callback
                def initialize(&block)
                        raise if block == nil
                        @block = block
                        @arity = block.arity
                        @cb    = CocoSimple::Generator.new
                        setup
                end
                        KERNEL32 =                         CocoSimple::DLL.new('Kernel32')
                ID_CALL = CFunc.new(CocoSimple::X['rb_intern']).call  "call"
                def setup
                        arity = @arity
                        blockvalue = @block.object_id*2
                        rb_funcall = CocoSimple::X['rb_funcall']
                        @runcode = @cb.run{
                                base   "coco/gen"
                                import :simplejit, :translate
                                clear
                                codebegin
                                arity.times{|x|
                                        revtrans((arity-x-1)*4+8)
                                }
                                push arity
                                push ID_CALL
                                push blockvalue
                                moveax rb_funcall
                                calleax arity*4+12
                                revret
                                leave
                                retn arity*4
                                @code
                        }

                        KERNEL32.FlushInstructionCache(KERNEL32.GetCurrentProcess, @runcode, @runcode.length)
                end
        
                def to_int
                        [@runcode].pack('p').unpack('L').first
                end
        end

end


require coco.stringConversion
require coco.variant
require coco.struct
require coco.template

info 'Artoria'   do require coco.artoria   end
info 'Generator' do require coco.generator end
info 'Bitmap' do require coco.ext.rgss.bitmap end
info 'Audio'  do require coco.ext.rgss.audio end
info 'Input'  do require coco.ext.rgss.input end
info 'udp'    do require coco.ext.network.udp; CocoSimple::UDPSocket.init end
info 'HGE'    do  require coco.ext.hge.hge; $hge = HGE::IHGE.new  end
info 'COMinit' do CocoSimple::COM.init end
info 'VBScript'    do
        $lang_vbs = CocoSimple::IUnknown.fromProgID('ScriptControl'.toUnicode, CocoSimple::GUID::IID_IDispatch).as(CocoSimple::IDispatch)
        $lang_vbs.Language = "VBScript"
end

info 'JScript'    do
        $lang_js = CocoSimple::IUnknown.fromProgID('ScriptControl'.toUnicode, CocoSimple::GUID::IID_IDispatch).as(CocoSimple::IDispatch)
        $lang_js.Language = "JScript"
end

require coco.ext.subworld.subworld


