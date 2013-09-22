module SD
  module Mixin
    module Transition
      def fade_in  frame = 60
        per = self.opacity / frame.to_f
        w   = 0.0
        self.opacity = 0
        while frame > 0
          w += per
          self.opacity = w
          update
          frame -= 1
        end
      end

      def fade_out frame = 60
        per = self.opacity / frame.to_f
        w   = self.opacity.to_f
        while frame > 0
          w -= per
          self.opacity = w
          update
          frame -= 1
        end
        dispose 
      end
 
    end
  end
end