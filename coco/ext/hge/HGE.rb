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

module HGE
        HGEDLL = CocoSimple::DLL.new 'C:/RMSFX/Coco/ext/hge/hge.dll'
        BASSDLL = CocoSimple::DLL.new 'C:/RMSFX/Coco/ext/hge/bass.dll'
        class IHGE < CocoSimple::IUnknown
                def initialize
                        ptr = HGEDLL.hgeCreate(HGE::VERSION)
                        super([[ptr].pack('L')].pack('p').unpack('L').first,
                                ptr)
                end
        end
        #init vtable decl
        HGEH=File.read('C:/RMSFX/Coco/ext/hge/hge.h')
        y = ""
        HGEH.split(/\n/).each{|x|
                	next if x =~ /^\s*$/
                	next if x[/inline/]
                	y << x[/([A-Za-z0-9_]+)\s*\(/, 1] + " " if x[
                        /([A-Za-z0-9_]+)\s*\(/, 1
                    ]
        }
        y = y[/Release.+hgeCreate/]
        y = y.split(/\s+/)
        IHGE.send :define_method, "__vtable__", lambda{y}
        #init consts
        HGEH.scan(/(HGE[A-Za-z0-9_]+)\s*=\s*([A-Za-z0-9_]+)/).each{|x|
                const_set x[0], x[1].to_i
                const_set x[0].sub(/^HGE_/){}, x[1].to_i
        }
        #init defines
        def self.DWORD(x)
                x
        end
        HGEH.scan(/#define[\t ]*(\S*)[\t ]*(.+)$/).each{|x|
                        begin
                         (class << self; self; end).
                                 send :class_eval,%Q{
                                         def #{x[0]}
                                                #{x[1]}
                                         end 
                                         def #{x[0].sub(/^HGE_/){}}
                                                #{x[1]}
                                         end
                                        } 
                        rescue SyntaxError
                        end
        }
        def self.const_missing(sym)
              return send sym if respond_to?(sym)
              super
        end
        #init simple structs
        TYPEDEF = HGEH.scan(/typedef (\S+) ([^\(\)\s;]+)/).map{|x|
                "typedef \"#{x[0]}\",\"#{x[1]}\";"
        }.join("\n")
        HGEH.scan(/struct\s*(\S+)\s*{([^}]*)}/).each{|x|
                name = x[0]
                cont = x[1]
                cont.gsub!(/([A-Za-z])\[(\d+)\]/){
                        aname, value = $1, $2
                        (0...value.to_i).to_a.map{|xx|
                                "#{aname}#{xx}"
                        } * ","
                }
                cont.gsub!(/\/\//){"#"} 
                r = CocoSimple::Struct.new(name, TYPEDEF + "def self.type():type end\n" + cont)
                name[0, 1] = name[0, 1].upcase  
                const_set name, r
                
        }

end
