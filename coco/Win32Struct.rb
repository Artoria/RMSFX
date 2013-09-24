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

module CocoSimple::Struct::Win32Struct
        public
        module_function
        def define_class name, *a
                     unless CocoSimple::Struct::Structs.include?(name.to_s)
                        raise 'Unknown Class #{name}'
                     end
                     klass = CocoSimple::Struct::Structs[name.to_s]
                     length = klass.sizeof
                     (class << self; self; end).send :define_method, name, lambda{|*a|
                                a.each{|x| ptr = @sizeof; @sizeof += length;
                                define_method x,           lambda{klass.new self, ptr, length}
                                define_method "#{x}=",     lambda{|val|@__data__[ptr, length] = val.__data__}
                        }
        }          
        end

        def define_primitive name, length = 4, packchar = 'L'
                  send :define_method, name, lambda{|*a|
                         a.each{|x| ptr = @sizeof; @sizeof += length;
                                  define_method x,           lambda{@__data__[ptr, length].unpack(packchar).first}
                                  define_method "#{x}=",     lambda{|val|
                                          __use__{
                                                  @__data__[ptr, length] =[val].pack(packchar)
                                          }
                                  }
                         }
                  }
        end

        def typedef name1, *name2
                name2.each{|x|
                        if self < (CocoSimple::CocoStruct)
                                (class << self; self; end).send :alias_method, x, name1 
                        else
                                alias_method  x, name1 
                        end
                }
        end

        define_primitive "int64", 8, "q"
        define_primitive "int32", 4, "l"
        define_primitive "int16", 2, "s"
        define_primitive "int8",  1, "c"
        define_primitive "uint64", 8, "Q"
        define_primitive "uint32", 4, "L"
        define_primitive "uint16", 2, "S"
        define_primitive "uint8",  1, "C"
        define_primitive "real32",  4, "F"
        define_primitive "real64",  8, "D"

        typedef "real32", "float", "FLOAT"
        typedef "real64", "double", "DOUBLE"
        typedef "int32",  "INT",   "BOOL", "LONG",   "int", "long"
        typedef "uint32", "DWORD", "UINT", "ULONG"
        typedef "uint16", "WORD"
        typedef "uint8",  "BYTE"
        typedef "int8"    "CHAR"
end
