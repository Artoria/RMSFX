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
   module Variant
        KERNEL32 = DLL.new('Kernel32')
        OLE32     = DLL.new('ole32')
        OLEAUT32 = DLL.new('oleaut32')

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
  
    def self.make_variant(tp,val,sig)
      ([tp,0,0,0,val].pack("SSSS"+sig)+"\0"*16)[0, 16]
    end
    
    def self.from(x, bstrs)
      case x
        when Integer then make_variant VT_I4,    x, 'l'
        when String  then 
          v = OLEAUT32.SysAllocString(x.toUnicode)
          bstrs << v
          make_variant VT_BSTR, v, 'L'
        when TrueClass then make_variant VT_BOOL,  -1, 's'
        when FalseClass then make_variant VT_BOOL,  0, 's'
        when NilClass then make_variant VT_EMPTY, 0, 'L'
        when IDispatch then make_variant VT_DISPATCH, x.this, 'L'
      end
    end
     
    def self.to(x)
      tp,_=x.unpack('SS')
      val     =x[8, 8]
      case tp
        when VT_I2 then val.unpack('s')[0]
        when VT_I4   then val.unpack('l')[0]
        when VT_BOOL then val.unpack('s')[0] == -1
        when VT_BSTR 
          bstraddr = val.unpack('l')[0]
          len  = IntPtr.new(bstraddr-4).indir.to_i
          buf = "\0"*len
          KERNEL32.RtlMoveMemory(buf, bstraddr, len)
          buf.fromUnicode
        when VT_EMPTY then nil
        when VT_DISPATCH then 
          lobj  = val[0,4]
          pobj  = lobj.unpack('L').first
          ppobj = [lobj].pack('p').unpack('L').first
          IDispatch.new(ppobj, pobj)
        else
          p "Type = "+tp.to_s
      end
    end
    
    def self.clearBSTR(x)
      x.each{|y|
        OLEAUT32.SysFreeString(y)
      }
      x.clear
    end
  end    
end
