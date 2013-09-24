module SD
  class Parent < Rect
    def self.screen
      new 0, 0, Graphics.width, Graphics.height
    end

    def initialize(*a)
      super
    end
    
    def rect
      self
    end

    include SD::Mixin::Position
  end
end