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

class Bitmap
        RBINFO = CocoSimple::Struct.new 'RGSSBMINFO' do
                DWORD _, _;
                DWORD infoheaderptr;
                DWORD firstRow, lastRow;
        end
        BFH = CocoSimple::Struct.new 'BITMAPFILEHEADER' do
                  WORD  bfType;          #=>0x4d42 
                  DWORD bfSize;
                  WORD  bfReserved1;
                  WORD  bfReserved2;
                  DWORD bfOffBits;       
        end
        def rgssbminfo
           RBINFO.new (
              CocoSimple::IntPtr.new(object_id*2+16).indir(8).indir[
                RBINFO.sizeof
              ]
           )
        end
        def addr
           CocoSimple::IntPtr.new(rgssbminfo.lastRow)
        end
        def infoheader
           CocoSimple::IntPtr.new(rgssbminfo.infoheaderptr)
        end

        def saveAs(filename)
                open(filename, 'wb'){|f|
                        len = width * height * 4
                        bf = BFH.new "BM0000\x00\x00\x00\x000000"
                        ih = infoheader[40]
                        bf.instance_eval do
                                self.bfSize = BFH.sizeof + ih.size  + len
                                self.bfOffBits = BFH.sizeof + ih.size
                        end
                        f.write bf.__data__
                        f.write ih
                        f.write addr[len]
                }
        end


end

class Bitmap
        GDI32 = CocoSimple::DLL.new('GDI32')
        KERNEL32 = CocoSimple::DLL.new('Kernel32')
        def createContext
                raise "Width must be multiple of 32" if width % 32 != 0
                @hdc     = GDI32.CreateCompatibleDC(0)
                @hbitmap = GDI32.CreateBitmap(width, height, 1, 32, addr)
                @hold    = GDI32.SelectObject(@hdc, @hbitmap)
                update
                GDI32.SelectObject(@hdc, @hold)
                GDI32.DeleteObject(@hbitmap)
                GDI32.DeleteDC(@hdc)
                @hdc     = GDI32.CreateCompatibleDC(0)
                @hbitmap = GDI32.CreateBitmap(width, height, 1, 32, addr)
                @hold    = GDI32.SelectObject(@hdc, @hbitmap)
        end
        def update
                hDIB     = KERNEL32.GlobalAlloc(0, width*height*4)
                lpBitmap = KERNEL32.GlobalLock(hDIB)
                bi       = infoheader[40]
                GDI32.GetDIBits(@hdc, @hbitmap, 0, height, lpBitmap,  bi,  0)
                addr[width*height*4] = hDIB
                KERNEL32.GlobalUnlock(hDIB)
                KERNEL32.GlobalFree(hDIB)
        end

        def deleteContext
                update
                GDI32.SelectObject(@hdc, @hold)
                GDI32.DeleteObject(@hbitmap)
                GDI32.DeleteDC(@hdc)
                @hdc = 0
        end
        def handle
                @hdc
        end
        alias hdc handle
        def method_missing(sym, *args)
                if x = sym.to_s[/gdig(.+)$/, 1]
                        GDI32.send x, *args
                elsif   x = sym.to_s[/gdi(.+)$/, 1]
                        GDI32.send x, @hdc, *args
                else
                        super
                end
        end
      
end

class Bitmap
        USER32 = CocoSimple::DLL.new('user32')
        RECT = CocoSimple::Struct.new do
                int32 left, top, right, bottom;
        end
        def self.fromHWND(hwnd, width = -1, height = -1)
                hdc = USER32.GetDC(hwnd)
                rect = RECT.new
                if width == -1
                        USER32.GetClientRect(hwnd, rect)
                        width = rect.right - rect.left
                        height = rect.bottom - rect.top
                end
                ret = self.fromHDC(hdc, width, height)
                USER32.ReleaseDC(hwnd, hdc)
                ret
        end
        def self.fromHDC(hdc, width = 32, height = 32)
                if width % 32 != 0
                        width += 32 - width % 32
                end
                bmp = new width, height
                bmp.instance_eval {
                        createContext
                        GDI32.BitBlt handle, 0, 0, width, height, hdc, 0, 0, srccopy = 0x00CC0020
                        deleteContext
                }
                bmp
        end
end
