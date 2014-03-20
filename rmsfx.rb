$: .unshift "C:/RMSFX"
ENV['path'] = "C:/RMSFX/bin;"+ENV['path']

require 's20'
require 'ver'

class Object
  def require *a
     Kernel.require *a
  end
end unless respond_to?(:require)


module RMSFX
  extend self
  def feature_only(*a)
    raise RuntimeError, "Only feature of #{a.inspect}", caller if a.select{|x| VER::const_get(x)}.empty?
  end
end

class Object
  include RMSFX
end
