require 'ext'
class LibVF < ExternalWrapper
  def self.init
     const_set :LIBVF, self.find(['libvorbisfile.dll'])
  end
  OV_CALLBACKS_NOCLOSE = [
        Seiran20.funcaddr('msvcrt', 'fread'),
        Seiran20.funcaddr('msvcrt', 'fseek'),
        0,
        Seiran20.funcaddr('msvcrt', 'ftell'),
  ].pack("L*")

  def self.decode_file(filename)
    fp = Seiran20.capi('msvcrt', 'fopen').call(filename, 'rb')
    vf = "\0"*4096
    self[:ov_open_callbacks].call fp, vf, 0, 0, OV_CALLBACKS_NOCLOSE
    buf = "\0"*4096
    cur = "RGBA"
    wavout = ""
    while (ret = self[:ov_read].call(vf, buf, 4096, 0,2,1,cur))!=0
       if ret > 0
         wavout << ret
         Graphics.update if VER::XP
       end
    end
   self[:ov_clear].call vf
    wavout
  end
  init

end
