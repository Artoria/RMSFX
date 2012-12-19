module Lang
  module_function
  
  def load_run(name)
    data = File.read(name)
    if data.unpack("C").first>=0x7f
      eval data[3, data.length-3],TOPLEVEL_BINDING,name,1
    else
      eval data,TOPLEVEL_BINDING,name,1
    end
  end
  
  def load_lit_module(name)
      load_run name
    rescue Object => ex
      print "���Բ���������\n\t"+
            "�쳣 #{ex.to_s}\n\t" +
            "ģ�� #{name}\n\t"    +
            "����\n\t#{ex.backtrace.join("\n")}"
      exit
  end
        
  def load_lit_modules
    open('C:/RMSFX/conf/lang.txt') {|f| load_lit_module "C:/RMSFX/plugins/#{$_.chomp}" if $_[0,1]!=';' while f.gets }
  end
  
  load_lit_modules
  
  class Lang::Opt
    def initialize(opt = {})
      @opt = opt
    end
  end
  
  # S::virtual����ζһ��Ҫʵ�֣����ǲ�ʵ��Ҳ���ᱨ��
  def virtual(*sym)
    sym.each{|x| send :define_method, x, lambda{|*_|} }
  end
  
end



