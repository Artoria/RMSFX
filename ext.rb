require 'ext'
require 'ver'
require 'dynamic'
class ExternalWrapper
   KERNEL32 = Roost::Dynamic::Dyn.new('kernel32')
   USER32   = Roost::Dynamic::Dyn.new('user32')
   GDI32    = Roost::Dynamic::Dyn.new('gdi32')
   PSAPI    = Roost::Dynamic::Dyn.new('psapi')
   ADVAPI32 = Roost::Dynamic::Dyn.new('advapi32')
   def self.find(dlls)
     dlls.each{|dll|
       (ENV["PATH"].split(";") + ["."]).reverse.each{|x|
         name = x.strip + "/" + dll
         if FileTest.file?(name)
             self.const_set :DLL, name
             return name
         end
       }
    }
  end
  CACHE = {}
  def self.[](a)
        CACHE[a] ||= Seiran20.capi(self.const_get(:DLL), a.to_s)
  end

end


