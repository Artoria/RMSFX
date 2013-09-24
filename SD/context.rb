module SD
  class Context
    include SD::Mixin::Text
    attr_accessor :bitmap, :root_layout, :object, :selectobj
    def initialize(bitmap, root_layout = nil, &block)
	self.bitmap      = bitmap
	reset &block
    end

    def reset &block
	self.object         = {}
	self.selectobj      = {}
   	@layout_stack = []
	instance_eval &block if block
    end

    def select id
	if self.object[id]
		self.selectobj[id] = self.object[id]
	end
    end

    def unselect id
	self.selectobj.delete id
    end


    def push_layout layout
	    @layout_stack.push layout
    end

    def pop_layout 
	    y = @layout_stack.pop
	    self.root_layout = y unless @layout_stack[-1]
	    @layout_stack[-1].push y if @layout_stack[-1]
    end

    STACK = []
    def refresh
	STACK.push self
	self.root_layout.draw(self.bitmap.rect) if self.root_layout
	STACK.pop
    end

    def self.current
	    STACK[-1]
    end

    def id id
	@id = id
    end
  end
end
