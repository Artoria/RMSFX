module SD
  module Mixin
    module Position
      attr_accessor :parent
      def centerx!
           self.x = parent.rect.width  / 2 - rect.width  / 2
           self
      end

      def centery!
           self.y = parent.rect.height / 2 - rect.height / 2
           self
      end

      def top! ratio = 0
           self.y = parent.rect.y + parent.height * ratio
           self
      end

      def left! ratio = 0
           self.x = parent.rect.x + parent.width * ratio
           self
      end

      def bottom! ratio = 0
           self.y = parent.rect.height - rect.height - parent.rect.height * ratio
           self
      end

      def right! ratio = 0
           self.x = parent.rect.width  - rect.width - parent.rect.width * ratio
           self
      end

      def center!
        if self.bitmap && !self.bitmap.disposed?
           self.centerx!.centery!
        else
	   nil
	end
      end

      def dock pos
         case pos
           when 1, 4, 7 then left!
           when 2, 5, 8 then centerx!
           when 3, 6, 9 then right!
         end
         case pos
           when 1, 2, 3 then bottom!
           when 4, 5, 6 then centery!
           when 7, 8, 9 then top!
         end
      end

      def special_rect pos, myrect
        case pos
          when 1..9
            rect = SD::Rect.new myrect.x, myrect.y, myrect.width, myrect.height
            rect.parent = self
            rect.dock pos
            rect

        end
      end

      def special_point pos
	  x, y = 0, 0
          case pos
           when 1, 4, 7 then x = self.rect.x
           when 2, 5, 8 then x = self.rect.x + self.rect.width / 2
           when 3, 6, 9 then x = self.rect.x + self.rect.width
         end
         case pos
           when 1, 2, 3 then y = self.rect.y + self.rect.height
           when 4, 5, 6 then y = self.rect.y + self.rect.height / 2
           when 7, 8, 9 then y = self.rect.y
         end
	 [x, y]
      end

      def pin pos, sdrect, pinpoint
	 s = sdrect
	 s = SD::Rect.new s.x, s.y, s.width, s.height if ::Rect === s
         self.x, self.y = s.special_point pinpoint
         x, y = special_point pos
	 self.x -= x - self.x
	 self.y -= y - self.y
         self
      end

    end
  end
end
