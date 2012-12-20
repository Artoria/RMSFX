require 's20'
require 'ext'
class Fixnum
  def to_dem
    [1, self].pack("LL")
  end
end

class Float
  def to_dem
    [2, self].pack("LF")
  end
end

class String
  def to_dem
    [3, self].pack("Lp")
  end
end

class Array
  def to_dem
    @dem = map{|x|x.to_dem}.join
    [-length, @dem].pack("Lp")
  end
end

class UnknownObject
  def initialize(ptr)
    @ptr = ptr
  end
  def to_dem
    @ptr
  end
  def inspect
        sprintf("UnknownObject [%08x, %08x]", *@ptr.unpack("LL"))
  end
end

class Object
  def self.from_dem(ptr)
    klass = ptr.unpack("l").first
    case klass
       when 1
          ptr[4,4].unpack("L").first
       when 2
          ptr[4,4].unpack("F").first
       when 3
          Seiran20.to_mb(Seiran20.to_wc(Seiran20.readstr ptr[4,4].unpack("L").first),0).chomp("\0")
       when 4
          Seiran20.to_mb(Seiran20.readwstr ptr[4,4].unpack("L").first).chomp("\0")
       
       else
         if klass < 0
            len = -klass * 8
            x = Seiran20.readmem(ptr[4,4].unpack("L").first, len)
            arr = []
            (len / 8).times{|z| arr.push Object.from_dem(x[z * 8, 8])}
            arr
        else
            UnknownObject.new(ptr)
        end
       end
  end
end


class DEM < ExternalWrapper
  def self.init
    find "dem.dll"
  end
  init
  DEMR = {}
  DEMRegisterName = Seiran20.callback{|obj, stack|
    name, obj = "\0"*8, "\0"*8
    self[:dem_pop].call stack, name
    self[:dem_pop].call stack, obj
    name = Seiran20.readstr(name[4,4].unpack("L").first)
    DEMR[name] = obj
  }
  DEMPushRegisterName = Seiran20.callback{|obj, stack|
    name  = "\0"*8
    self[:dem_pop].call stack, name
    name = Seiran20.readstr(name[4,4].unpack("L").first)
    self[:dem_push_ptr].call stack, DEMR[name]
  }
  def self.callback(&block)
    arity = block.arity
    raise "error" if arity < 0
    Seiran20.callback{|obj, stack|
      arr = []
      obj = "\0"*8
      arity.times{
       DEM[:dem_pop].call stack, obj
       arr.push Object.from_dem(obj)
      }
      self[:dem_push_ptr].call stack, block.call(*arr).to_dem
    }
  end
  def self.new(size)
      DEM[:dem_new].call size
  end
  def self.pushptr(stack, dem)
      DEM[:dem_push_ptr].call stack, dem
  end

  def self.push(stack, tp, value)
      DEM[:dem_push_object].call stack, tp, value
  end
  def self.top(stack)
      obj = "\0"*8
      DEM[:dem_pop].call stack, obj
      Object.from_dem(obj)
  end
  def self.push_string(stack, x)
      DEM[:dem_push_object].call stack,3,x.to_ptr
  end

  def self.push_wstring(stack, x)
      DEM[:dem_push_object].call stack,4,x.to_ptr
  end


  def self.push_name(stack, name)
      push_string stack, name
      DEM[:dem_push_register].call stack, 1
      DEM[:dem_call_stack_stdcall].call stack
  end
  
  def self.call(stack)
      DEM[:dem_call_stack_stdcall].call stack
  end

  def self.call_by_name(stack, name)
      push_name stack, name
      call stack
  end

  def self.pop(stack)
      obj = "\0"*8
      DEM[:dem_pop].call stack, obj
      Object.from_dem(obj)
  end

  def self.unpack(stack, number)
      arr = []
      obj = "\0"*8
      arity.times{
        DEM[:dem_pop].call stack, obj
        arr.push Object.from_dem(obj)
      }
      arr
  end
  def self.register_function(stack, name, func)
    DEM[:dem_push_object].call stack, self.callback(&func).to_ptr, 0
    DEM[:dem_push_object].call stack, 3, name.to_ptr
    DEM[:dem_push_register].call stack, 0
    DEM[:dem_call_stack_stdcall].call stack
  end
  DEM[:dem_register_object].call 0, DEMRegisterName.to_ptr, 0
  DEM[:dem_register_object].call 1, DEMPushRegisterName.to_ptr, 0
end



