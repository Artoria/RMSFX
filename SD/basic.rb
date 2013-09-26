module SD
  class BasicDialog < Sprite    
    def update
  #    uyvgyjrf7y 22:08 2013/9/20
        Graphics.update
        Input.update
        super
	update_cursor
    end


    
    attr_accessor :showing
    def pass
        update
        onkey :C if Input.trigger? Input::C
        onkey :B if Input.trigger? Input::B 


    end

    def update_cursor
        @cursor_sprite.x, @cursor_sprite.y = self.x, self.y
	@cursor_sprite.update
	if @cursor_sprite.opacity  == 255
		@cursor_sprite_dx = -6
	elsif @cursor_sprite.opacity  <= 128
		@cursor_sprite_dx =  6
	end
	@cursor_sprite.opacity += @cursor_sprite_dx
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
      self.parent = SD::GameScreen.all
      @cursor_sprite = Sprite.new self.viewport
      @cursor_sprite.z = self.z + 10
    end
    #context
    def context
	@context ||= SD::Context.new self.bitmap
    end

    def refresh
        context.refresh
	@cursor_sprite.bitmap.clear
	context.selectobj.each{|k, v|
		@cursor_sprite.bitmap.fill_rect(v.rect.original_rect, Color.new(127, 127, 127, 127))
	}
	@cursor_sprite_dx = 1
    end

    #rect
    def rect
        SD::Rect.new(self.x, self.y, self.bitmap.width, self.bitmap.height)
    end

    include Mixin::Position
    include Mixin::OnKey
    include Mixin::OnInitBitmap
    include Mixin::Text
    include Mixin::SimpleControl
    include Mixin::Transition

    def oninitbitmap bitmap
	x = @cursor_sprite.bitmap
	x.dispose if x && !x.disposed?
	@cursor_sprite.bitmap = Bitmap.new(self.bitmap.width, self.bitmap.height)
    end

    def dispose
	@cursor_sprite.dispose
	super
    end
  end
end
