module SD
  module Mixin
    module SimpleControl
      def show_until_esc
        show_modal_special do
          self.showing = false if Input.trigger? Input::B
        end
      end
    end
  end
end