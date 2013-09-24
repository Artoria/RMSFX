require 'ext'
class ExtRuby < ExternalWrapper
  FIX_MUTEX = %{
    class Mutex
     def synchronize
      self.lock
      begin
       yield
      ensure
        self.unlock rescue nil
      end
     end
    end
  }
  def self.findRuby
     const_set :Ruby, self.find(['msvcrt-ruby191.dll', 'msvcrt-ruby18.dll'])
  end


  Sleep = Seiran20.callback(:cdecl){|*a| sleep(0.1)}
  def self.fixup
     self.eval("require 'dl'")
     if self._eval("Mutex.instance_methods.include?(:synchronize)") == 0
        self._eval FIX_MUTEX
     end

     self[:rb_define_global_function].call "rgsssleep", Sleep.to_ptr, -1
  end

  def self.init
     unless constants.include?(:Ruby)
        findRuby
     end
     self[:ruby_sysinit].call "\0"*8, "\0"*8
     self[:ruby_init].call
     self[:ruby_init_loadpath].call
     self.fixup
  end

  def self._eval str
     self[:rb_eval_string_protect].call str, 0
  end

  def self.eval str
     Object.new{self._eval str}
  end

  class Object
     attr_accessor :objid

     def initialize(id = nil, &block)
        if id
                @objid = case id
                    when false   then 0
                    when true    then 2
                    when nil     then 4
                    when Fixnum  then id * 2 + 1
                    else ExtRuby._eval("Marshal.load #{Marshal.dump(id).inspect}")
                end
        else
                @objid = block && block.call
        end
     end

     def __type__
        remote_instance_eval "self.class"
     end

     def __value__
        case @objid
                when 0 then false
                when 2 then true
                when 4 then nil
                else 
                  if @objid % 2 == 1
                     @objid / 2
                  else
                    if __type__.objid == StringClass.objid
                        ptr = ExtRuby[:rb_string_value_ptr].call([@objid].pack('L'))
                        len = ExtRuby[:rb_str_length].call(@objid) / 2
                        Seiran20.readmem(ptr, len)
                    else
                        Marshal.load remote_instance_eval("Marshal.dump self").__value__
                    end
                  end
        end
     end


     def self
        "(DL::dlunwrap(#{@objid}))"
     end

     def remote_instance_eval str
        ExtRuby.eval %{  #{self.self}.instance_eval #{str.inspect} }
     end

     def remote_class_eval str
        ExtRuby.eval %{ #{self.self}.class_eval #{str.inspect} }
     end


    ([:require, :eval]).each{|q| define_method(q){|*a| method_missing(q, *a)}}
     def method_missing(sym, *args)
        remote_instance_eval "self.#{sym}(#{args.map{|x|Object.new(x).self}.join(",")})"
     end

  end

  class Toplevel_Object < Object
    def self
      '(eval("self", TOPLEVEL_BINDING))'
    end
  end

  init

  TOPLEVEL = Toplevel_Object.new
  StringClass = TOPLEVEL.remote_instance_eval("String")
end
