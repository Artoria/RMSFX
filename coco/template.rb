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

# == Overview
#
#     Roost PreProcessor is a simple text preproccessor,
# like C Preprocessor, but just very simple and can't be an
# alternative.
# 
#     Roost::PP only support one form:
#       identifier{...}
#     where the curly brace '{''}' can be nested
#       identifier{ {} {...}... }
#     you can change the brace into '[', ']' or other
#
#     Suppose you have a class :
#      class A 
#        def double_str(pp, a)
#           pp.act(a)*2
#        end
#      end
#
#     and the text is:
#      
#        doubled string of "ABC" is "double_str{ABC}"
#
#     then  Roost::PP.new(A.new).act(text) will be
# 
#        doubled string of "ABC" is "ABCABC"
#     
#       because double_str is an instance method of class A
#     so "double_str{...}" is processed by the instance of class A
#     
class CocoSimple::PP
      LB = "\\{"
      RB = "\\}" 
      REGEXP = /(?<a>([_A-Za-z]+))(?<b>#{LB}(((([^#{LB}#{RB}]|\g<b>)*)))#{RB})/
      REGEX  = /\A([_A-Za-z]+)#{LB}([\w\W]*)#{RB}\Z/
      def initialize(obj=nil, re1=REGEXP, re2=REGEX)
                     @obj=obj;@re1=re1;   @re2=re2;
      end
      def act(code)
        code.gsub(@re1){
            next $& unless @obj.respond_to?($1)  
            begin
              p=$&
              x=p.match(@re2).to_a
              @obj.send x[1], self, x[2]
            rescue => ex
              throw "#{p} \n #{ex}"
            end
            #these x[1], self, x[2] do not look smooth, however, which is the cost of M-expr rather than S-expr
        }
      end
end

=begin usage
  class A
    def abc(pp, x)
      pp.act(x).upcase
    end
    def rsh(pp, x)
      pp.act("abc{xyz#{x}zyx}")
    end
    def expr(pp, x)
      eval(x)
    end
  end
  pr
  int Roost::PP.new(A.new).act("abc{def,abc{ghi}} rsh{123} expr{3+5}")
=end

