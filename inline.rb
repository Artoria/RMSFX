require 'metasm'
require 's20'

module RGSSInline
  class Builder
      def initialize(mod)
        @mod = mod
        @encoded = []
      end
      
      def c(str)
        @encoded << [str, u = Metasm::Shellcode.compile_c(Metasm::Ia32.new, str)]
          
        q = Metasm::Ia32.new.new_cparser
        q.parse str, @mod.to_s, 1
        
        base = [u.encoded.data].pack("p").unpack("L").first
        
        u.encoded.reloc.each{|k, v|
        
          ex = Metasm::Expression[v.target]
          r = ex.reduce{|a|
            (u.encoded.export[a] || (Seiran20.funcaddr('user32', a) - base) || (Seiran20.funcaddr('msvcrt', a) - base)) + base
          }
          Seiran20.writemem(base + k, 4, [r].pack("L"))
        }
        
        q.toplevel.statements.select{|x| x.is_a?(Metasm::C::Declaration)}.each{|k|
          var = k.var
          next unless var.class != Metasm::C::Function
          
          
          c = Seiran20.callproc(base + u.encoded.export[k.var.name.to_s])  rescue next
          @mod.send :define_method, k.var.name.to_sym do |*a|
            ret = c.call(*a)
            
            if var.type.type.is_a?(Metasm::C::Pointer)  
              return Seiran20.readstr(ret) if var.type.type.base.name == :char
            end
            
            case var.type.type.base.name
              when :void
                nil
              when :long, :int
                ret
              when :float
                [ret].pack("L").unpack("f").first
            end
          end
        }
      end
      
      def c_raw(str)
        @encoded << [str, u = Metasm::Shellcode.compile_c(Metasm::Ia32.new, str)]
        q = Metasm::Ia32.new.new_cparser
        q.parse str, @mod.to_s, 1
        q.toplevel.statements.select{|x| x.is_a?(Metasm::C::Declaration)}.each{|k|
          var = k.var
          next unless var.class != Metasm::C::Function
          
        
          
          c = [u.encoded.data].pack("p").unpack("L").first + 
                                 u.encoded.export[k.var.name.to_s]
                                 
                                 
          Seiran20.callproc(Seiran20::RGSSX[0]).call(
            @mod.object_id*2,
            k.var.name.to_s,
            c,
            -1
          )
          
        }
      end
  end
  
  module Module
    def inline
      yield Builder.new(self)
    end
  end
  
  ::Module.send :include, Module
end

class A
  inline do |builder|
    builder.c "
      long factorial(int max){
        int i=max, result=1;
        while (i >= 2) { result *= i--; }
        return result;
      }
      
      char *test(){
        return \"Hello\";
      }
      
      char *test_reverse(char *st){
        char *ed = st;
        int n = 0, i;
        while(*ed) ++ ed, ++n;
        
        for(i = 0; i < n - i - 1; ++i){
          char p = st[i]; st[i] = st[n - i - 1]; st[n - i - 1] = p;
        }
        return st;
      }
       
      
      
      void test_msgbox(char *msgbox){
         int __stdcall MessageBoxA(int, char *, int, int);
         MessageBoxA(0, msgbox, 0, 16);
      }
    "
    
    builder.c_raw "
       int add(int argc, int *argv, int self){
         return argv[0] + argv[1] - 1;
       }
    
    "
  end
end
