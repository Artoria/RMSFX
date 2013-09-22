require 'sd'

def sdsprite(bmp)
  bmp = Bitmap.new bmp unless Bitmap === bmp
  s = SD::BasicDialog.new
  s.bitmap = bmp
  s
end

