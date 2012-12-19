module CocoSimple::SubWorld
        module EvalModule
                @@id = 0
                def eval(str, 
                        bind = binding, 
                        file = nil, 
                        line = nil, 
                        lang = :cpp)
                        send "eval_#{lang}",str, bind = binding, file || "<eval-#{lang}>", line || 1
                end
                def alloc(text = nil)
                        Dir.mkdir("DynTmp") rescue 1
                        Dir.mkdir("Dynamic") rescue 1
                        @@id += 1                    
                        if text == nil
                                ["", @@id.to_s]
                        else
                                open(filename = "DynTmp/eval#{@@id}", "w"){|f| f.write text}
                                [filename, @@id.to_s]
                        end
                end
        end
        module EvalCpp
                class CPPBinding
                        def initialize
                                @str = {}
                        end
                        def ruby(pp, x)
                                x = pp.act(x)
                                @str[x] ||= x
                                "rb_funcall(4,#{ID_EVAL}, 2, #{@str[x].object_id*2},binding)"
                        end
                end
                ID_EVAL = CocoSimple::CFunc.new(CocoSimple::X['rb_intern']).call "eval"
                HEADER = %Q{typedef unsigned int(*rubyfunc)(...);\n#define func extern "C" int __stdcall func(rubyfunc rb_funcall,  unsigned int binding)}
                def eval_cpp(str, bind = binding, file = "<eval-cpp>", line = 1)
                        str = CocoSimple::PP.new(CPPBinding.new).act(str)
                        q, id = alloc("#{HEADER}\n#{str}")
                        name = "Dynamic\\#{id}.dyn"
                        `g++ -pipe -xc++ #{q} -std=c++0x -o #{name} -shared -static -Wl,-fadd-stdcall-alias`
                        CocoSimple::DLL.new(name).send "func@8", CocoSimple::X['rb_funcall'], binding.object_id*2
                end
        end
        module EvalASM
                class ASMBinding
                        def initialize
                                @str = {}
                        end
                        def ruby(pp, x)
                                x = pp.act(x)
                                @str[x] ||= x
                                        "push 12(%ebp) 
                                        push $#{@str[x].object_id*2}
                                        push $2
                                        push $#{ID_EVAL}
                                        push $4
                                        call 8(%ebp)
                                        add $20, %esp"
                                
                        end
                end
                ID_EVAL = CocoSimple::CFunc.new(CocoSimple::X['rb_intern']).call "eval"
                ASMHEADER = %Q{.global _func@8\n_func@8:}
                def eval_asm(str, bind = binding, file = "<eval-cpp>", line = 1)
                        str = CocoSimple::PP.new(ASMBinding.new).act(str)
                        q, id = alloc("#{ASMHEADER}\n#{str}")
                        name = "Dynamic\\#{id}.dyn"
                        `g++ -pipe -xassembler #{q} -std=c++0x -o #{name} -shared -static -Wl,-fadd-stdcall-alias`
                        CocoSimple::DLL.new(name).send "func@8", CocoSimple::X['rb_funcall'], binding.object_id*2
                end
        end

        class Eval
                include EvalModule
                include EvalCpp
                include EvalASM
        end
end
