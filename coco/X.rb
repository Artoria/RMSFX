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
class Integer
        def ord
                self
        end
end
module CocoSimple
        module X
                ASCIICHAR = [0].pack('C') 
                Kernel32 = CocoSimple::DLL.new('kernel32')
        		PSAPI    = CocoSimple::DLL.new('psapi')
                def self.findRGSS
                        process = Kernel32.GetCurrentProcess
        				num = "\0"*4
        				PSAPI.EnumProcessModules process, 0, 0, num
        				num = num.unpack('L')[0]
        				x = "\0"*(num*8)
        				lnum = "\0"*4
        				PSAPI.EnumProcessModules process, x, num, lnum
        				x = x.unpack('L*')
        				x.each{|xx|
        						buf = ASCIICHAR * 1024     #avoid RMVA encoding
        						Kernel32.GetModuleFileName xx, buf, 1024
        						buf = buf.gsub(/\0.+$/){}
        						r = File.basename(buf)
        						if Kernel32.GetProcAddress(xx, "RGSSEval")!=0           						
                                        return [buf, xx]
        						end
        				}
        				['', 0]
                end
                def self.modinfo(hrgss)
                        modinfo = "\0"*12
                        cur = Kernel32.GetCurrentProcess
                        PSAPI.GetModuleInformation cur, hrgss, modinfo, 12
                        modinfo.unpack("L*")
                end
                def self.findstr(fl, x)
                        len = x.length
                        len2 = fl.length
                        k = fl.index(x)
                        ret = []
                        while k != nil
                          ret << k
                          k = fl.index(x, k+1)
                        end      
                        ret
                end
                def self.findpushstr(fl, arr)
                        q = []
                        arr.each{|x|
                          r = [x+RGSSBASE].pack('L')          
                          ret = findstr(fl, r)
                          q.concat ret
                        }
                        q
                end      
                def self.findsomething(fl, name1)
                      gr = findstr fl, name1
                      findpushstr fl, gr
                end
                def self.findnearest(grr, udd)
                      ans = 1e100
                      l = -1
                      r = -1
                      grr.each_with_index{|x, i|
                        udd.each_with_index{|y, j|
                          if  y>x && y-x < ans
                            ans = y-x
                            l = x
                            r = y
                          end
                        }
                      }
                      [l, r]
                end
                def self.findcall(fl, l , t = 0)
                      t.times{
                        l+=1 while fl[l].ord != 0xe8 
                        l+=1
                      }
                      l+=1 while fl[l].ord != 0xe8
                      fl[l+1, 4].unpack('L')[0]+l+5
                end
                def self.litpair(a, b)
                        a, b = a+"\0", b+"\0"
                        if RUBY_VERSION > "1.9" #RMVA
                                a, b = a.force_encoding("ASCII-8BIT"), b.force_encoding("ASCII-8BIT")
                        end
                        grr = findsomething(RGSSTEXT, a)
                        udd = findsomething(RGSSTEXT, b)
                        findnearest(grr, udd)
                end
        end
end

module CocoSimple::X
                RGSS, HRGSS                     = findRGSS
                RGSSBASE, RGSSLEN, RGSSENTRY    = modinfo HRGSS
                RGSSTEXT                        = ASCIICHAR * RGSSLEN
                Kernel32.RtlMoveMemory  RGSSTEXT, RGSSBASE, RGSSLEN
                l, r = litpair("Graphics", "update")
                @addrs = {}
                @addrs['rb_define_module']          = findcall(RGSSTEXT, l) + RGSSBASE
                @addrs['rb_define_module_function'] = findcall(RGSSTEXT, r) + RGSSBASE
                l, r = litpair("Bitmap", "initialize")
                @addrs['rb_define_class']          = findcall(RGSSTEXT, l) + RGSSBASE
                @addrs['rb_define_method']         = findcall(RGSSTEXT, r) + RGSSBASE
                l, r = litpair("Marshal", "dump")
                @addrs['rb_intern']               = findcall(RGSSTEXT, r) + RGSSBASE
                @addrs['rb_funcall']              = findcall(RGSSTEXT, r, 1) + RGSSBASE
                def self.[] *a
                        @addrs.[] *a
                end
                def self.[]= *a
                        @addrs.[]= *a
                end
end

