module SD
  module Mixin
    module OnInitBitmap
      def oninitbitmap bitmap;      end
      def bitmap= *a
        super 
        oninitbitmap self.bitmap
      end
    end
    module OnKey
      def onkey key; end
    end
  end
end