import struct
import ctypes

ret = ''

def dem_int_function(func):
  def q(dem):
    length, arr = struct.unpack("ii", dem)
    length = -length
    array = ctypes.string_at(arr, length * 8)
    fmt = str(length) + "Q"
    array = struct.unpack(fmt, array)
    array = map(lambda x:x>>32, array)
    result = func(*array)
    ret  =  struct.pack('ii', 1, result)
    return ret
  return q
      
@dem_int_function
def add(*args):
  return reduce(lambda x,y:x+y, args)
