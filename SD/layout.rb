module SD
	class Layout
	        include SD::Mixin::Position	
		attr_accessor :children, :layout, :layout_args, :rect
		def initialize(layout = nil, layout_args = {})
		  self.children = []
		  self.layout = layout
 		  self.layout_args = layout_args
		end

		def push obj
		  self.children.push obj
		end

		def size(rect, obj = nil)
   		  self.layout.size(rect, self)
		end

		def draw(rect)
  		  self.rect = self.layout.draw(rect, self)
		end

		module Horizonal
			def self.size(rect, layout)
				bitmap = SD::Context.current.bitmap
				args = layout.layout_args
				children = layout.children
			     	rect = SD::Rect.new rect
				len = children.length.to_f
				r = 0
				case true
				when args[:origin]
					top = rect.y
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.y = top
						top += r.height
					}
					SD::Rect.new rect.x, rect.y, rect.width,top - rect.y
				when args[:fixed]
					top = rect.y
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.y = top
						top += args[:fixed_size]
					}
					SD::Rect.new rect.x, rect.y, rect.width, top - rect.y

				else
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.parent = rect
						r.top! i / len
					}
					SD::Rect.new rect.x, rect.y, rect.width, top - rect.y
				end
			end
			def self.draw(rect, layout)
				bitmap = SD::Context.current.bitmap
				args = layout.layout_args
				children = layout.children
			     	rect = SD::Rect.new rect
				len = children.length.to_f
				r = 0
				case true
				when args[:origin]
					top = rect.y
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.y = top
						top += r.height
						dust.draw r
					}
					SD::Rect.new rect.x, rect.y, rect.width, top - rect.y
				when args[:fixed]
					top = rect.y
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.y = top
						top += args[:fixed_size]
						dust.draw r
					}
					SD::Rect.new rect.x, rect.y, rect.width,top - rect.y

				else
					children.each_with_index{|dust, i|
						r = dust.size rect
						r.x = rect.x
						r.parent = rect
						r.top! i / len
						dust.draw r
					}
					SD::Rect.new rect.x, rect.y, rect.width,top - rect.y
				end
			end
		end
		module MainBorder
			def self.size(rect, layout)
				SD::Rect.new rect
			end
			def self.draw(rect, layout)
				args  = layout.layout_args
				bitmap = SD::Context.current.bitmap
				children = layout.children
				rect = SD::Rect.new rect
				color = args[:color]
				size  = args[:size]
				bitmap.fill_rect(0, 0, bitmap.width, size, color)
				bitmap.fill_rect(0, 0, size, bitmap.height, color)
				bitmap.fill_rect(0, bitmap.height - size, bitmap.width, size, color)
				bitmap.fill_rect(bitmap.width - size, 0, size, bitmap.height, color)
				children.each{|x| x.draw(SD::Rect.new(size, size, rect.width - 2*size, rect.height-2*size))}
				rect
			end
		end
		module Background
			def self.size(rect, layout)
				SD::Rect.empty
			end
			def self.draw(rect, layout)
				args  = layout.layout_args
				bitmap = SD::Context.current.bitmap
				children = layout.children
				rect = SD::Rect.new rect
				color = args[:color]
				bitmap.fill_rect(rect.original_rect, color)
				children.each{|x| x.draw(SD::Rect.new(rect))}
				rect
			end
		end

	end
end
