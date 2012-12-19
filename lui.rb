module TestShow
  module_function
  def create_background
    bitmap = Bitmap.new(640, 480)
    color = [Color.new(63,63,63,63), Color.new(127,127,127,63)]
    k = 0
    (640 / 32).times{|x|
      (480 / 32).times{|y|
        bitmap.fill_rect(x * 32, y * 32, 32, 32, color[k])
        k ^= 1
      }
    }
    bitmap
  end
  
  def show(bitmap)
    t = Sprite.new
    t.bitmap = create_background
    s = Sprite.new
    s.bitmap = bitmap
    loop do
      Graphics.update
      Input.update
      s.update
      yield if block_given?
      break if Input.trigger?(Input::B)
    end
  end
end


class Target < Bitmap
  attr_accessor :clip
  def roi # region of interest
    self.clip || self.rect
  end
  def text(text, align = 1)
    draw_text( self.roi, text, align )
  end
  def blt(target, opacity = 255)
    super( self.roi.x, self.roi.y, target, target.roi, opacity )
  end
  def stretch_blt(target, opacity = 255)
    super( self.roi, target, target.roi, opacity )
  end
  def fill(color)
    fill_rect( self.roi, color )
  end
  def clone_roi
    roi = self.roi
    target = Target.new(roi.width, roi.height)
    target.blt(self)
    target
  end
  def boundary
    self.roi
  end
end

class UI
  def parse
    @chars.each do |x|
      case x
        when 0
          @list.push @text
          @list.push :draw
          @text = ""
        when 1
          @list.push @text
          @list.push :justpush
          @text = ""
        when 2
          @list.push @text
          @list.push :teval
          @text = ""
        when 3
          @list.push @text
          @list.push :seval
          @text = ""
        when 4
          @list.push @text
          @list.push :sevalesc
          @text = ""
        when 5
          @list.push :blt
        when 10
          @list.push @text
          @list.push :newline
          @text = ""
        else
          @text << x.chr
      end
    end
  end
  
  
  def do_render
    @stack = []
    @rects = []
    @rects_named = {}
    @id = 0
    @cx, @cy = 0, 0
    @cw, @ch = nil, nil
    @hw = 0
    @list.each{|x|
        case x
          when :draw
            text = @stack.pop
            rect = text_size(text)
            rect.x, rect.y = @cx, @cy
            if @cw && @ch
              rect.width, rect.height = @cw, @ch
              @cw = @ch = nil
            end
            unless @nofocus
              @rects[@id] = rect
              @id += 1
              if @name 
                @rects_named[@name] = rect
                @name = nil
              end
            end
            @cx += rect.width
            @hw = [rect.height, @hw].max
            @target.clip = rect
            @target.text(text)
          when :teval
            @target.instance_eval @stack.pop
          when :seval
            instance_eval @stack.pop
          when :sevalesc
            instance_eval escape @stack.pop
          when :newline
            @cy += @hw
            @cx = 0
            @hw = 0
          when :blt
            name = @stack.pop            
            newtarget = Target.new(name)
            rect = text_size(newtarget)
            rect.x, rect.y = @cx, @cy
            if @cw && @ch
              rect.width, rect.height = @cw, @ch
              newtarget.clip = Rect.new(0, 0, @cw, @ch)
              @cw = @ch = nil
            end
            unless @nofocus
              @rects[@id] = rect
              @id += 1
              if @name 
                @rects_named[@name] = rect
                @name = nil
              end
            end
            @cx += rect.width
            @hw = [rect.height, @hw].max
            @target.clip = rect
            @target.blt(newtarget)
            newtarget.dispose
          when :justpush
          else
            @stack.push x
        end
    }
  end
  
  def text_size(x)
    if x.respond_to?(:boundary)
      x.boundary
    else
      @target.text_size(x)
    end
  end
  
  def render(target, text)
    @target = target
    @chars = text.unpack('C*')
    @list = []
    @text  = ""
    parse
    do_render
  end
  
end


