=begin
#
# module Libpng
# 
# $Id: libpng wrapper $
# 
# Created by Hana Seiran 
#
# Documentation by Hana Seiran
#
=end

# == Overview
#
# Simple Libpng wrapper, now integrates save_png/save_ico/save_bmp
#

require 'ext'
class Libpng < ExternalWrapper
  def self.init
     const_set :LIBPNG, self.find(['libpng3.dll'])
  end
  VERSION = "1.2.37"
  init

  # get the address pointer(in Fixnum) of a RGSS Bitmap
  #    
  def self.ptr(bitmap)
    x = bitmap.object_id*2
    v = Seiran20.readmem(x + 16, 4).unpack('L').first
    v = Seiran20.readmem(v + 8, 4).unpack('L').first
    v = Seiran20.readmem(v + 16, 4).unpack('L').first
  end

  # save a bitmap to filename in png format, 32 bit color, default compression
  #    
  def self.save_png(filename, bitmap)
     fp = Seiran20.capi('msvcrt', 'fopen').call(filename, 'wb')
     png  = self[:png_create_write_struct].call(VERSION,0,0,0)
     info = self[:png_create_info_struct].call png
     self[:png_init_io].call png, fp
     self[:png_set_IHDR].call png, info, bitmap.width, bitmap.height,8, 6, 0, 0, 0
     firstptr =  ptr(bitmap)
     rowptr = (0...bitmap.height).to_a.map{|x| firstptr + bitmap.width * x * 4}
     self[:png_set_rows].call png, info, rowptr.reverse.pack('L*')
     self[:png_write_png].call png, info, 0x80, 0
     Seiran20.capi('msvcrt', 'fclose').call(fp)
  end

  # save a bitmap to filename in ico format
  #    
 def self.save_ico(filename, bitmap)
  x = bitmap
  open(filename, "wb"){|f| 
    f.write [0, 1, 1].pack("S*")
    size = 40 + x.width*x.height*4 + x.height * ((x.width + 31) / 32 * 32 / 8)
    f.write [x.width, x.height, 0, 0, 1, 32, size,22].pack("CCCCSSLL")
    f.write [40, x.width, 2*x.height, 1, 32, 0,0,0,0,0,0].pack("LLLSSL*")
    f.write Seiran20.readmem(Libpng.ptr(x), x.width*x.height*4)
    f.write "\x0"*(x.height * ((x.width + 31) / 32 * 32 / 8))
  }
 end

 # save a bitmap to filename in bmp format
 #    
 def self.save_bmp(filename, bitmap)
  x = bitmap
  open(filename, "wb"){|f| 
    size = 40 + x.width*x.height*4
    f.write [0x4d42, x.width*x.height*4 + 40 + 14, 0, 0, 54].pack("SLSSL")
    f.write [40, x.width, x.height, 1, 32, 0,x.width*x.height*4,0,0,0,0].pack("LLLSSL*")
    f.write Seiran20.readmem(Libpng.ptr(x), x.width*x.height*4)
  }
 end

end
