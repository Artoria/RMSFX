class DEM_CIL 
  XX = DEM.new(1024)
  DLL = "testclr"
  STATIC = Win32API.new(DLL, "StaticCall", "i", "v")
  OBJECT = Win32API.new(DLL, "ObjectCall", "i", "v")
  PGET = Win32API.new(DLL, "PropertyGet", "i", "v")
  PSET = Win32API.new(DLL, "PropertySet", "i", "v")
  def self.StaticCall(name, met, *args)
    args.map!{|x|  x.is_a?(String) ? Seiran20.to_wc(x+"\0") : x}
    args.reverse!
    args.each{|x| x.is_a?(String) ? DEM.push_wstring(XX, x) : DEM.pushptr(XX,x.to_dem)}
    DEM.push XX, 1, args.length
    DEM.push_wstring XX, Seiran20.to_wc(met+"\0")
    DEM.push_wstring XX, Seiran20.to_wc(name+"\0")
    STATIC.call XX
    DEM.pop XX
  end
  def self.ObjectCall(obj, met, *args)
    args.map!{|x|  x.is_a?(String) ? Seiran20.to_wc(x+"\0") : x}
    args.reverse!
    args.each{|x| x.is_a?(String) ? DEM.push_wstring(XX, x) : DEM.pushptr(XX,x.to_dem)}
    DEM.push XX, 1, args.length
    DEM.push_wstring XX, Seiran20.to_wc(met+"\0")
    DEM.pushptr XX, obj.to_dem
    OBJECT.call XX
    DEM.pop XX
  end
  def self.PropertyGet(obj, prop, *args)
    args.map!{|x|  x.is_a?(String) ? Seiran20.to_wc(x+"\0") : x}
    args.reverse!
    args.each{|x| x.is_a?(String) ? DEM.push_wstring(XX, x) : DEM.pushptr(XX,x.to_dem)}
    DEM.push XX, 1, args.length
    DEM.push_wstring XX, Seiran20.to_wc(prop+"\0")
    DEM.pushptr XX, obj.to_dem
    PGET.call XX
    DEM.pop XX
  end
  def self.PropertySet(obj, prop, *args)
    args.map!{|x|  x.is_a?(String) ? Seiran20.to_wc(x+"\0") : x}
    args.reverse!
    args.each{|x| x.is_a?(String) ? DEM.push_wstring(XX, x) : DEM.pushptr(XX,x.to_dem)}
    DEM.push XX, 1, args.length-1
    DEM.push_wstring XX, Seiran20.to_wc(prop+"\0")
    DEM.pushptr XX, obj.to_dem
    PSET.call XX
    DEM.pop XX
  end
end

class DEM_CIL_Object
   def initialize(obj)
      @obj = obj
    end
    def argmap(args)
      args.map{|x|
      x.is_a?(DEM_CIL_Object) ? 
        x.obj :
        x
      }
    end
    def retmap(ret)
      if ret.is_a?(UnknownObject)
        DEM_CIL_Object.new ret
      else
        ret
      end
    end
    def method_missing(sym, *args)
      retmap DEM_CIL.ObjectCall(@obj, sym.to_s, *argmap(args))
    end
    
    def [](sym, *args)
      retmap DEM_CIL.PropertyGet(@obj, sym.to_s, *argmap(args))
    end
    def []=(sym, *args)
      retmap DEM_CIL.PropertySet(@obj, sym.to_s, *argmap(args))
    end
    attr_accessor :obj
end

class DEM_CIL_Class
  def self.forName(name)
    new(name)
  end
  def initialize(name)
    @name = name
  end
  def method_missing(sym, *args)
      args.map!{|x|
      x.is_a?(DEM_CIL_Object) ? 
        x.obj :
        x
      }
        
      ret = DEM_CIL.StaticCall(@name, sym.to_s, *args)
      if ret.is_a?(UnknownObject)
        DEM_CIL_Object.new ret
      else
        ret
      end
  end
  def new(*args)
    args.map!{|x|
      x.is_a?(DEM_CIL_Object) ? 
        x.obj :
        x
      }
    ret = DEM_CIL.StaticCall(@name, ".ctor", *args)
    if ret.is_a?(UnknownObject)
      DEM_CIL_Object.new ret
    else
      ret
    end
  end
end
