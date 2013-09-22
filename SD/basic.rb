module SD
  class BasicDialog < Sprite    
    def update
  #    uyvgyjrf7y 22:08 2013/9/20
        Graphics.update
        Input.update
        super
    end
    
    attr_accessor :showing
    def pass
        update
        onkey :C if Input.trigger? Input::C
        onkey :B if Input.trigger? Input::B 
    end

    def show_modal
        return nil if self.showing
        self.visible = true
        self.showing = true
        pass while self.showing
        self
    end

    def show_modal_special 
        return nil if self.showing
        self.visible = true
        self.showing = true
        [pass, yield] while self.showing
        self
    end


    def initialize *a
      super *a
      self.parent = Parent.screen
    end

    def rect
        Rect.new(self.x, self.y, self.bitmap.width, self.bitmap.height)
    end

    include Mixin::Position
    include Mixin::OnKey
    include Mixin::OnInitBitmap
    include Mixin::Text
    include Mixin::SimpleControl
    include Mixin::Transition
  end
end
