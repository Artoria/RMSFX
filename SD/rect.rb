module SD
  class Rect < ::Rect
    def self.screen
      SD::GameScreen.all
    end
    def self.empty 
      new 0, 0, 0, 0
    end

    def initialize(*a)
      if a[0].is_a?(::Rect)
        super a[0].x, a[0].y, a[0].width, a[0].height
      elsif a[0].is_a?(self.class)
	set a[0].x, a[0].y, a[0].width, a[0].height
      else
	 super(*a) rescue (print $!.backtrace*"\n")
      end
    end
    
    def rect
      self
    end

    def original_rect
      ::Rect.new(x, y, width, height)
    end

    def dup
      self.class.new self
    end

    def size
      self.class.new 0, 0, width, height
    end
    alias clone dup

    include SD::Mixin::Position
  end
end
