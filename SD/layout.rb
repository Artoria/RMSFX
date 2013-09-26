module SD
	class Layout
	        include SD::Mixin::Position	
		attr_accessor :children, :layout, :layout_args, :rect, :id
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
				halfcolor = Color.new(color.red, color.green, color.blue, color.alpha)
				halfcolor.alpha = halfcolor.alpha * 4 / 5
				size  = args[:size]
				orientation = args[:orientation] || 15
				bitmap.fill_rect(0, 0, bitmap.width, size, ((orientation & 8) != 0) ? color : halfcolor)
				bitmap.fill_rect(0, 0, size, bitmap.height, ((orientation & 4) != 0) ? color : halfcolor)
				bitmap.fill_rect(bitmap.width - size, 0, size, bitmap.height, ((orientation & 2) != 0) ? color : halfcolor)
				bitmap.fill_rect(0, bitmap.height - size, bitmap.width, size, ((orientation & 1) != 0) ? color : halfcolor)

				if bitmap.height > 2 && args[:second_color]
					color = args[:second_color]
					halfcolor = Color.new(color.red, color.green, color.blue, color.alpha)
					halfcolor.alpha = halfcolor.alpha * 4 / 5
   					bitmap.fill_rect(1, 1, bitmap.width - 2, 1, ((orientation & 8) != 0) ? color : halfcolor)
					bitmap.fill_rect(1, 1, 1, bitmap.height - 2, ((orientation & 4) != 0) ? color : halfcolor)
					bitmap.fill_rect(bitmap.width - 2, 1, 1, bitmap.height - 2, ((orientation & 2) != 0) ? color : halfcolor)
					bitmap.fill_rect(1, bitmap.height - 2, bitmap.width - 2, 1, ((orientation & 1) != 0) ? color : halfcolor)

				end

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
				if args[:windowskin]
					bm = Bitmap.new args[:windowskin]
					case args[:skin_type]
						when :xp
							u = rect.original_rect
							u.x += 1
							u.y += 1
							u.width -= 2
							u.height -= 2
							bitmap.stretch_blt u, bm, ::Rect.new(1, 1, 126, 126)
							bitmap.blt 0, 0, bm, ::Rect.new(128, 0, 16, 16)
							bitmap.blt rect.width-16, 0, bm, ::Rect.new(176, 0, 16, 16)
							bitmap.blt rect.width-16, rect.height-16, bm, ::Rect.new(176, 48, 16, 16)
							bitmap.blt 0, rect.height-16, bm, ::Rect.new(128, 48, 16, 16)
							children.each{|x| x.draw(SD::Rect.new u)}
						when :vx, :va
							bitmap.stretch_blt rect.original_rect, bm, ::Rect.new(0, 0, 64, 64)
							children.each{|x| x.draw(rect)}	
					        when :all
							bitmap.stretch_blt rect.original_rect, bm, bm.rect
							children.each{|x| x.draw(rect)}
					end
					bm.dispose
				else
					bitmap.fill_rect(rect.original_rect, color)
				children.each{|x| x.draw(rect)}
				end

				rect
			end
		end

	end
end
