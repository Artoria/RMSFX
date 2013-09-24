import ctypes
from ctypes import *
import struct

CALL_STACK_STDCALL = WINFUNCTYPE(c_int, c_int, c_int)
DEM = ctypes.cdll.dem
stack = 0
callbacklist = []

def log(line):
  f = open("dem.log","a")
  f.write(str(line))
  f.close

def current():
  return stack

def call_by_name(stack = None):
    stack = stack or current()
    push_string(name, stack)
    DEM.dem_push_register(stack, 1)
    DEM.dem_call_stack_stdcall(stack)
    DEM.dem_call_stack_stdcall(stack)

def pop(stack = None):
    stack = stack or current()
    x = ctypes.create_string_buffer(8)
    DEM.dem_pop(stack, x)
    tp, value = struct.unpack('ii', x.raw)
    if tp == 1:
      return value
    if tp == 2:
      return struct.unpack('if', x.raw)[1]
    if tp == 3:
      return ctypes.string_at(value)

def unpack(argnumber, stack = None):
  args = []
  stack = stack or current()
  for i in range(0, argnumber):
    x = ctypes.create_string_buffer(8)
    DEM.dem_pop(stack, x)
    tp, value = struct.unpack('ii', x.raw)
    if tp == 1:
      args.append(value)
    if tp == 2:
      args.append(struct.unpack('if', x.raw)[1])
    if tp == 3:
      args.append(ctypes.string_at(value))
  return args
    
def push_int(value, stack = None):
  stack = stack or current()
  DEM.dem_push_int(stack, value)

def push_string(value, stack = None):
  stack = stack or current()
  DEM.dem_push_object(stack, 3, value)

def ret_object(tp, value, stack = None):
  stack = stack or current()
  DEM.dem_push_object(stack, tp, value)


def register_dem_function(name, func, stack = None):
  stack = stack or current()
  global DEM
  global callbacklist
  callbacklist.append(CALL_STACK_STDCALL(func))
  DEM.dem_push_object(stack,callbacklist[-1] , 0)
  DEM.dem_push_object(stack, 3, name)
  DEM.dem_push_register(stack, 0)
  DEM.dem_call_stack_stdcall(stack)
  
   
        
def init(dem_stack):
  global stack
  stack = dem_stack

