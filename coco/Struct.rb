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
        class CocoStruct
        end
        class Struct
                module MethodMissingAsName
                     def method_missing(sym, *a)
                          if Structs.include?(sym.to_s) 
                                  define_class(sym, *a)
                                  send sym, *a
                          else
                                  sym.to_s
                          end
                     end
                end
                module TypeSizeOf
                    attr_accessor :sizeof
                    attr_accessor :typeof
                end
                Structs = {}
                class << self
                    alias classnew new
                end
                def self.new *a, &block
                        klass = Class.new(CocoSimple::CocoStruct)
                        name, *a = a
                        Structs[name] = klass if name!='' && name != nil
                        if block
                                setup klass, a[0], &block
                        else
                                setup klass, a[0]
                        end
                        klass
                end
                def self.setup ___x, ___y, &block
                        class << ___x
                                include TypeSizeOf
                                include MethodMissingAsName
                                include Win32Struct
                        end
                        ___x.instance_eval "
                                @sizeof = 0
                                @typeof = self
                        "
                        ___x.class_eval ___y if ___y
                        ___x.class_eval &block if block
                        ___x.class_eval %Q{
                                def __data__()  @__data__ end
                                def to_int
                                        [__data__].pack('p').unpack('L').first
                                end
                                def initialize(*a, &block)
                                        if a.length == 0
                                                @__data__ = "\0"*#{___x.sizeof}
                                                __use__ &block if block

                                        elsif a.length == 1
                                                @__data__ = a.first
                                                __use__ &block if block
                                        else
                                                @obj, @begin, @len = a
                                                @__data__ = @obj.__data__[@begin, @len]
                                        end
                                end
                                def __use__(&block)
                                        yield @__data__
                                        @obj.__use__{|data| data[@begin, @len] = @__data__} if @obj           
                                end
                        }
                end
        end
end

require 'Coco/Win32Struct.rb'

