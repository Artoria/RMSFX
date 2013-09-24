module SD
  module Mixin
    module Transition
      def fade_in  frame = 60
        per = self.opacity / frame.to_f
        w   = 0.0
        self.opacity = 0
        while frame > 0
          w += per
          self.opacity = w.to_i
          update
          frame -= 1
        end
      end

      def fade_out frame = 60
        per = self.opacity / frame.to_f
        w   = self.opacity.to_f
        while frame > 0
          w -= per
          self.opacity = w.to_i
          update
          frame -= 1
        end
        dispose 
      end

      def push_bitmap
	      @bitmaps ||= []
	      @bitmaps.push self.bitmap
	      self.bitmap = Bitmap.new(self.bitmap.width, self.bitmap.height)
	      self.bitmap.blt(0, 0, @bitmaps[-1], @bitmaps[-1].rect)
      end

      def pop_bitmap
	      self.bitmap.dispose
	      self.bitmap = @bitmaps.pop
      end

      def fly_in dir, base = SD::GameScreen.all, frame = 60
	      tx, ty = self.x, self.y
	      pin 10 - dir, base, dir
	      px, py = (tx - self.x)/frame.to_f, (ty - self.y)/frame.to_f
	      wx, wy = self.x, self.y
	      while frame > 0
		      self.x, self.y = (wx += px), (wy += py)
		      frame -= 1
		      update
	      end
      end

      def dissolve frame = 60
	    push_bitmap
	    u = @bitmaps[-1]
	    self.bitmap.clear
	    w, h = self.bitmap.width, self.bitmap.height
            while frame > 0
               1000.times{|x, y|
		       x, y = rand(w), rand(h)
		       self.bitmap.set_pixel x, y, u.get_pixel(x, y)
	       }
	       frame -= 1
	       update
            end
	    pop_bitmap
      end
	     
 
    end
  end
end
