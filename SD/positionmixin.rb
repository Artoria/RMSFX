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

      def top!
           self.y = parent.rect.y
           self
      end

      def left!
           self.x = parent.rect.x
           self
      end

      def bottom!
           self.y = parent.rect.height - rect.height
           self
      end

      def right!
           self.x = parent.rect.width  - rect.width
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
            rect = SD::Parent.new myrect.x, myrect.y, myrect.width, myrect.height
            rect.parent = self
            rect.dock pos
            rect
        end
      end

    end
  end
end