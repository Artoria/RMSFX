require 'sd'


def sdsprite(bmp, &b)
  bmp = Bitmap.new bmp unless Bitmap === bmp
  s = SD::BasicDialog.new
  s.bitmap = bmp
  s.instance_eval &b if b
end

def sdcurrent
	SD::Context.current
end
