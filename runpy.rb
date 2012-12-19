require 'ext'
module Python
        def self.runfile(filename)
        SimplePipe.run("python #{filename}", 10240).sub(/\0+$/){}
#system("cmd /k python #{filename}")
        end
end


class PyMod < ExternalWrapper  
  def self.init(mod)
     self.find(["python26.dll"])
     pythondir = File.dirname(DLL)
     self[:Py_Initialize].call
     self[:PyRun_SimpleString].call %{
import sys
}

self[:PyRun_SimpleString].call %{
try:
  sys.path.append("C:\\RMSFX")
  sys.path.append(r'#{pythondir}\\DLLs')
  sys.path.append(r'#{pythondir}\\lib')
  import ctypes
  import dem
  import struct
  dem.init(#{mod})
except Exception as exp:
  f = open("runpy.log", "w")
  f.write(str(type(exp)))
  f.write(str(exp.args))
  f.write(str(sys.path))
  f.close
}
  end

  def self.runsimple(string)
     self[:PyRun_SimpleString].call %{
import dem
import struct
#{string}
}
  end
  
  def self.eval(string)
     self[:PyRun_SimpleString].call %{
def func():
#{string}

try:
  import dem
  import struct
  func()
except Exception as exp:
  f = open("runpy.log", "w")
  f.write(str(type(exp)))
  f.write(str(exp.args))
  f.write(str(sys.path))
  f.close
}
end
end

