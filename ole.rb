  VT_EMPTY = 0x0000
  VT_NULL = 0x0001
  VT_I2 = 0x0002
  VT_I4 = 0x0003
  VT_R4 = 0x0004
  VT_R8 = 0x0005
  VT_CY = 0x0006
  VT_DATE = 0x0007
  VT_BSTR = 0x0008
  VT_DISPATCH = 0x0009
  VT_ERROR = 0x000A
  VT_BOOL = 0x000B
  VT_VARIANT = 0x000C
  VT_UNKNOWN = 0x000D
  VT_DECIMAL = 0x000E
  VT_I1 = 0x0010A
  VT_UI1 = 0x0011
  VT_UI2 = 0x0012
  VT_UI4 = 0x0013
  VT_I8 = 0x0014
  VT_UI8 = 0x0015
  VT_INT = 0x0016
  VT_UINT = 0x0017
  VT_VOID = 0x0018
  VT_HRESULT = 0x0019
  VT_PTR = 0x001A
  VT_SAFEARRAY = 0x001B
  VT_CARRAY = 0x001C
  VT_USERDEFINED = 0x001D
  VT_LPSTR = 0x001E
  VT_LPWSTR = 0x001F
  VT_RECORD = 0x0024
  VT_INT_PTR = 0x0025
  VT_UINT_PTR = 0x0026
  VT_ARRAY = 0x2000
  VT_BYREF = 0x4000
  
module RubyWood
  KERNEL32 = Prelude::FFI.new('kernel32')
  OLE32 = Prelude::FFI.new('ole32')
  OLEAUT32 = Prelude::FFI.new('oleaut32')
  def self.initCOM
      OLE32.CoInitialize(0)
  end
  def self.finiCOM
      OLE32.CoUninitialize()
  end
  module GuidHelper
    def self.fromStr(x)
        a = x.split(/-/).map{|x| x.to_i(16)}
        a.pack('LSSC*')
    end
  end
  module CLSIDHelper
    def self.fromStr(x)
      buf = "\0"*16
      if OLE32.CLSIDFromProgID(x, buf) != 0
        raise "CLSIDFromProgID : Can't find #{x}"
      end
      buf
    end
  end

  class IntPtr
    RMM = Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'i')
    RMM2 = Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'i')
    def addr; @addr; end;
    def initialize(addr)
      @addr = addr
    end
    def [](len)
      str = "\0"*len
      RMM.call(str, @addr, len)
      str
    end
    def []=(len, buf)
      RMM2.call(@addr,buf,len)
    end
    def indir(x=0)
      IntPtr.new(self[4].unpack('L')[0]+x)
    end
    def offset(x=0)
      IntPtr.new(@addr+x)
    end
    def to_i
      @addr
    end
    def to_ptr
      @addr
    end
    def to_hex
      @addr.to_s(16)
    end
  end

  class IUnknown    
    attr_accessor :ppObj
    def initialize
      @ppObj = Seiran20.api("kernel32", "GlobalAlloc").call 0, 16
      KERNEL32.RtlZeroMemory(@ppObj, 16)
      @vtbl  = {}
    end
    
    def ppObjPtr
      @ppObj.to_i
    end
    def dispose
      unless @vtbl[:Release]
        add_method(2, :Release)
      end
      self.Release
      Seiran20.api("kernel32", "GlobalAlloc").call(@ppObj)
    end
    def init_table
      __vtable__.each_with_index{|x,i| add_method(i,x)}
    end
    def __vtable__
      %w(QueryInterface AddRef Release)
    end
    def obj
      ptr.indir.to_i
    end
    
    def ptr
      IntPtr.new(@ppObj)
    end
    
    def vtbl(index)
      ptr.indir.indir(index*4).indir
    end
    
    def add_method(index, name)
      @vtbl[index] = name
      addr = vtbl(index)
      func = Seiran20.callproc(addr, :stdcall)
        (class << self; self; end).send :define_method, name, lambda{|*args|
         args.unshift obj
         q = args.dup
         a = q.map{|x| x.is_a?(Integer) ? x : [x.dup].pack('p').unpack('L')[0]}
         ret = func.call *a
         q = []
         ret
      }
    end
  end
  
  module VariantHelper
    def self.make_variant(tp,val,sig)
      ([tp,0,0,0,val].pack("SSSS"+sig)+"\0"*16)[0, 16]
    end
    
    def self.toVariant(x, bstrs)
      case x
        when Integer then make_variant VT_I4,    x, 'l'
        when String  then 
          v = OLEAUT32.SysAllocString(x.u2w)
          bstrs << v
          make_variant VT_BSTR, v, 'L'
        when TrueClass then make_variant VT_BOOL,  -1, 's'
        when FalseClass then make_variant VT_BOOL,  0, 's'
        when NilClass then make_variant VT_EMPTY, 0, 'L'
        when IDispatch then make_variant VT_DISPATCH, x.obj, 'L'
      end
    end
    
    def self.fromVariant(x)
      tp,_=x.unpack('SS')
      val     =x[8, 8]
      case tp
        when VT_I4   then val.unpack('l')[0]
        when VT_BOOL then val.unpack('s')[0] == -1
        when VT_BSTR 
          bstraddr = val.unpack('l')[0]
          len  = IntPtr.new(bstraddr-4).indir.to_i
          buf = "\0"*len
          KERNEL32.RtlMoveMemory(buf, bstraddr, len)
          buf.w2u
        when VT_EMPTY then nil
        when VT_DISPATCH then 
          v = IDispatch.new
          IntPtr.new(v.ppObj)[4]=val[0, 4]
          v.init_table
          v
        else
          msgbox "Type = "+tp
      end
    end
    
    def self.clearBSTR(x)
      x.each{|y|
        OLEAUT32.SysFreeString(y)
      }
      x.clear
    end
  end    
  class IDispatch < IUnknown
    IID_IDispatch = GuidHelper.fromStr("00020400-0000-0000-C0-00-00-00-00-00-00-46")
    IID_NULL      = GuidHelper.fromStr("00000000-0000-0000-00-00-00-00-00-00-00-00")
    CLSCTX_ALL    = 1+2+4+16
    LOCALE_SYSTEM_DEFAULT = 0x0800
    DISPATCH_METHOD          =  1
    DISPATCH_PROPERTYGET    =  2
    DISPATCH_PROPERTYPUT    =  4
    DISPID_PROPERTYPUT = -3
    
    def bstrs
      @bstrs ||= []
    end
    def create(id)
      clsid = CLSIDHelper.fromStr(id.u2w)
      hr= OLE32.CoCreateInstance(clsid, 0, CLSCTX_ALL, IID_IDispatch, ppObjPtr)
      if hr!=0
        p ((hr + (1<<32) ) % (1<<32)).to_s(16)
        return false
      end
      init_table
    end
    
    def __vtable__
      super + %w(GetTypeInfoCount GetTypeInfo GetIDsOfNames Invoke)
    end
    
    def address_helper(x)
      m = [x].pack('p')
      if block_given?
        yield m 
      else
        [m, x]
      end
    end
    
    
    def call(name, *args)
      dispids = "\0"*16
      x = [name.u2w].pack('p')
      hr = GetIDsOfNames(IID_NULL, x, 1, LOCALE_SYSTEM_DEFAULT, dispids)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      
      id =  dispids.unpack('L')[0]
      args.map!{|x| VariantHelper.toVariant(x, bstrs)}
      ar = args.reverse.join
      dp = [ar, 0, args.length, 0].pack('pLLL')
      result = "\0"*16
      hr = Invoke(id, IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD, dp, result, 0, 0)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      ret = VariantHelper.fromVariant(result)
      VariantHelper.clearBSTR(bstrs)
      ret
    end
    
    def propertyput(name, *args)
      dispids = "\0"*16
      x = [name.u2w].pack('p')
      hr = GetIDsOfNames(IID_NULL, x, 1, LOCALE_SYSTEM_DEFAULT, dispids)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      id =  dispids.unpack('L')[0]
      args.map!{|x| VariantHelper.toVariant(x, bstrs)}
      ar = args.reverse.join
      dispnamed = [DISPID_PROPERTYPUT].pack('L')
      dp = [ar, dispnamed, args.length, 1].pack('ppLL')
      result = "\0"*16
      hr = Invoke(id, IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD | DISPATCH_PROPERTYPUT, dp, result, 0, 0)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      ret = VariantHelper.fromVariant(result)
      VariantHelper.clearBSTR(bstrs)
      ret
    end
    
    def __get(name, *args)
      dispids = "\0"*16
      x = [name.u2w].pack('p')
      hr = GetIDsOfNames(IID_NULL, x, 1, LOCALE_SYSTEM_DEFAULT, dispids)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      id =  dispids.unpack('L')[0]
      args.map!{|x| VariantHelper.toVariant(x, bstrs)}
      ar = args.reverse.join
      dp = [ar, 0, args.length, 0].pack('pLLL')
      result = "\0"*16
      hr = Invoke(id, IID_NULL, LOCALE_SYSTEM_DEFAULT, DISPATCH_METHOD | DISPATCH_PROPERTYGET, dp, result, 0, 0)
      if hr!=0 
        msgbox ((hr + (1<<32) ) % (1<<32)).to_s(16)
      end
      
      ret = VariantHelper.fromVariant(result)
      VariantHelper.clearBSTR(bstrs)
      ret
    end
    def method_missing(sym, *args)
      unless sym[/=$/]
        (class << self; self; end).send :define_method, sym, lambda{|*arg|
            call sym.to_s, *arg
        }
      else
        x = sym.to_s
        x=x[0, x.length-1]
        (class << self; self; end).send :define_method, sym, lambda{|*arg|
            propertyput x, *arg
        }
        
      end
      send sym, *args
    end
  end


=begin
  CLSID_CLRRuntimeHost = GuidHelper.fromStr("90F1A06E-7712-4762-86B5-7A5EBA6BDB02")
  IID_ICLRRuntimeHost  = GuidHelper.fromStr("90F1A06C-7712-4762-86B5-7A5EBA6BDB02")
  msgbox mscoree.CorBindToRuntimeEx(0,0,0,CLSID_CLRRuntimeHost, IID_ICLRRuntimeHost, ptr)
=end

  CLSID_CLRMetaHost    = GuidHelper.fromStr("9280188D-0E8E-4867-B3-0C-7F-A8-38-84-E8-DE")
  IID_ICLRMetaHost     = GuidHelper.fromStr("D332DB9E-B9B3-4125-82-07-A1-48-84-F5-32-16")
  IID_ICLRRuntimeInfo  = GuidHelper.fromStr("BD39D1D2-BA2F-486A-89-B0-B4-B0-CB-46-68-91")
  CLSID_CLRRuntimeHost = GuidHelper.fromStr("90F1A06E-7712-4762-86-B5-7A-5E-BA-6B-DB-02")
  IID_ICLRRuntimeHost  = GuidHelper.fromStr("90F1A06C-7712-4762-86-B5-7A-5E-BA-6B-DB-02")
  def self.L(x)
    x.u2w
  end
  def self.net
    mscoree = Prelude::FFI.new("mscoree.dll")
    @@host = IUnknown.new
    hr = mscoree.CLRCreateInstance(CLSID_CLRMetaHost, IID_ICLRMetaHost, @@host.ppObjPtr)
    if hr!=0
      print ((hr + (1<<32) ) % (1<<32)).to_s(16)
      return false
    end
    @@host.add_method(3, :GetRuntime)
    
    @@runtime = IUnknown.new
    hr = @@host.GetRuntime((L "v4.0.30319"), IID_ICLRRuntimeInfo, @@runtime.ppObjPtr)
    if hr!=0
      print ((hr + (1<<32) ) % (1<<32)).to_s(16)  + "\n(You may need dotnetfx 4.0.30319?)"
      return false
    end
    
    @@runtime.add_method(9, :GetInterface)
    @@runtimehost = IUnknown.new
    
    hr = @@runtime.GetInterface(CLSID_CLRRuntimeHost, IID_ICLRRuntimeHost, @@runtimehost.ppObjPtr)
    if hr!=0
      print ((hr + (1<<32) ) % (1<<32)).to_s(16)
      return false
    end
    
    @@runtimehost.add_method(2,  :Release)
    @@runtimehost.add_method(3,  :Start)
    @@runtimehost.add_method(11, :ExecuteInDefaultAppDomain)

    @@runtimehost.Start
  end
  
  def self.runclrdll(dll,cls,method, arg)
    pret = "\0"*8
    @@runtimehost.ExecuteInDefaultAppDomain(dll.u2w, 
                                        cls.u2w,
                                        method.u2w,
                                        arg.u2w,
                                        pret)
    pret.unpack('L')[0]
  end
  #net
end

class String
  def u2w
   Seiran20.to_mb(self)
  end
  def w2u
   Seiran20.to_wc(self)
  end
end
