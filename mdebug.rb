

require 's20'
require 'metasm'

module MDebug
  include Seiran20
  extend self

  
  def u(addr = @lastaddr || Seiran20::RGSS, len = 16)
    @lastaddr = addr + len
    api('Kernel32', 'VirtualProtect').call addr, len, 0x40, "RGBA"
    sc = Metasm::Shellcode.decode(readmem(addr, len), Metasm::Ia32.new)
    sc.base_addr = addr
    STDOUT.reopen("nul")
    z = sc.disassemble
    STDOUT.reopen("conout$")
    STDOUT.puts z.to_s
    nil
  end

  def d(addr = @lastaddr || Seiran20::RGSS, len = 16)
    @lastaddr = addr + len
  STDOUT.reopen("conout$")
    (len / 16).times{|a|
      STDOUT.puts sprintf("%08x : %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x",  addr + a * 16, *readmem(addr + a * 16, 16).unpack("C*"))
    }
    
    st = len / 16
    rest = len % 16 
    STDOUT.puts sprintf("%08x :"+ " %02x" * rest,  addr + st * 16, *readmem(addr + st * 16, rest).unpack("C*")) if rest != 0
    nil
  end
  
end