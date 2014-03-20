$: .unshift "C:/RMSFX"
ENV['path'] = "C:/RMSFX/bin;"+ENV['path']


class Object
  def require *a
     Kernel.require *a
  end
end unless respond_to?(:require)

require 's20'
require 'ver'

module RMSFX
  extend self
  def feature_only(*a)
    raise RuntimeError, "Only feature of #{a.inspect}", caller if a.select{|x| VER::const_get(x)}.empty?
  end
end

class Object
  include RMSFX
end
