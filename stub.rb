=begin
#
# class SimplePipe
# 
# $Id: Simple Piping $
# 
# Created by Hana Seiran 
#
# Documentation by Hana Seiran
#
=end

# == Overview
#
# Run process in background, feeding with given stdin, fetching stdout/stderr
#

class ::SimplePipe
   STUB = Win32API.new("stub.dll", "runpipe", "ppippi", "i")
   def self.getRGSS
  	getModuleHandle = Win32API.new("kernel32", "GetModuleHandle", "p", "i")
	arr = %w(
		rgss102
		rgss102j
		rgss102E
		rgss103j
		rgss103E
		rgss200j
		rgss200e
		rgss202j
		rgss300
		rgss300
	)
	arr.each{|x|
		if (handle = getModuleHandle.call(x))!=0
			self.const_set :RGSSName, x			
			self.const_set :RGSSHandle, handle
			return [handle, x]
		end
	}		 
   end
   
   self.getRGSS
   if constants.include?(:RGSSHandle)
	   RGSSEvalPtr = Win32API.new('Kernel32', 'GetProcAddress', 'ip', 'i').call(RGSSHandle, "RGSSEval")
	   RGSSEval    = Win32API.new(RGSSName, "RGSSEval", 'p', 'i')
   end

   # remove trailing "\0" in s
   def self.strip(s)
      s[0, s.index("\0")||0]
   end   

   # Run given command line(cmd), with given stdin and  max stdout/stderr size 
   # returns [strip(stdout), strip(stderr), exitcode, stdout, stderr]

   def self.runpipe(cmd, stdin, maxsize = -1)
      maxsize = stdin.length if maxsize == -1
      stdout = "\0"*maxsize
      stderr = "\0"*maxsize
      ret=STUB.call(cmd, stdin, stdin.length, stdout, stderr, maxsize)
      return [strip(stdout), strip(stderr), ret, stdout, stderr]
   end
 
   def self.waitfunction
      Graphics.update
      Input.update
      if Input.trigger?(Input::C) or Input.trigger?(Input::B)
          print "SimplePipe Running"
       end  
   end
   def self.runpipeRMXP(cmd, stdin, maxsize = -1)
      maxsize = stdin.length if maxsize == -1
      stdout = "\0"*maxsize
      stderr = "\0"*maxsize
      ret=STUBRMXP.call(cmd, stdin, stdin.length, stdout, stderr, maxsize, RGSSEvalPtr, "SimplePipe.waitfunction")
      return [strip(stdout), strip(stderr), ret, stdout, stderr]
   end

   # Run given command line(cmd), with max stdout/stderr size 
   # returns stdout
   def self.run(cmd, maxsize = 1024)
      stdin = "\0"*maxsize
      stdout = "\0"*maxsize
      stderr = "\0"*maxsize
      ret=STUB.call(cmd, stdin, stdin.length, stdout, stderr, maxsize)
      stdout  
   end
end





