module SD
	class Dust
		attr_accessor :content, :content_type, :id, :rect, :redraw_block
		def initialize(content, content_type, &block)
			self.content      = content
			self.content_type = content_type
			self.redraw_block = block || lambda{true}
		end
		def draw(rect)
			redraw = self.redraw_block.call
			if redraw != @redraw
				self.rect = self.content_type.draw(rect, self)
				@redraw = redraw
			end
		end
		def size(rect = nil)
			SD::Rect.new self.content_type.size(rect, self)
		end
		def context
			SD::Context.current
		end

		module Text
			def self.size(rect, dust)
				SD::Context.current.bitmap.text_size dust.content
			end
			def self.draw(rect, dust)
				SD::Context.current.bitmap.draw_text rect.original_rect, dust.content
				rect
			end
		end
		module ShadowedText
			def self.size(rect,dust)
				return SD::Rect.empty if dust.content[:absolute]
				rect=::Rect.new(0,0,rect.width,rect.height)
				bmp=Bitmap.new(1,1)
				srect=bmp.text_size(to_ss(dust.content))
				#if SD::Context.current.shadow
				srect.width+=1
				srect.height+=1
				#end
				bmp.dispose
				Rect.new(x=[rect.x,srect.x].max,y=[rect.y,srect.y].max,[rect.width,srect.width].min-x,[rect.height,srect.height].min-y)
			end
			def self.draw(rect,dust)
				bmp=Bitmap.new( (srect=self.size(rect, dust)).width,srect.height )
				if dust.content[:absolute]
					srect = dust.content[:absolute]
				end
				bmp.font=(bitmap= SD::Context.current.bitmap ).font
				bmp.draw_text(srect,to_ss(dust.content))
				x=(align=self.align(dust.content))==0 ? rect.x : align==2 ? rect.x+rect.width-srect.width : rect.x+(rect.width-srect.width)/2
				y= rect.y+(rect.height-srect.height)/2 
				if dust.content[:absolute]
					x,y=dust.content[:absolute].x,dust.content[:absolute].y
				end

				bitmap.blt(x,y,bmp,srect)
				bmp.dispose

				srect

			end
			def self.align(content)
				if content.is_a?(Hash)
					if align=content[:align]
						return align
					end
				end
				SD::Context.current.align 
			rescue
				0
			end
			def self.to_ss(content)
				case content
				when Hash
					content[:text]
				when String
					content
				else
					raise TypeError
				end
			end
		end
		module Picture
			def self.size(rect,dust)
				return SD::Rect.empty if dust.content[:absolute]
				bmp=Bitmap.new get_bmp(dust.content)
				srect=bmp.rect
				rect=Rect.new(0,0,rect.width,rect.height)
				bmp.dispose
				Rect.new(x=[rect.x,srect.x].max,y=[rect.y,srect.y].max,[rect.width,srect.width].min-x,[rect.height,srect.height].min-y) 

			end
			def self.draw(rect,dust)
				bmp=Bitmap.new get_bmp(dust.content)
				align=align(dust.content)
				srect=(ss=self.size(rect,dust)).original_rect
				
				bitmap=SD::Context.current.bitmap
				case align
				when 0
					srect = dust.content[:absolute].size.original_rect if dust.content[:absolute]
					rect = dust.content[:absolute] if dust.content[:absolute]
					bitmap.stretch_blt(rect.original_rect,bmp,srect)#名字和参数都忘了……
					bmp.dispose
					rect
				when 1..9

					if dust.content[:absolute]
						srect = dust.content[:absolute].size.original_rect
						x = dust.content[:absolute].dup 
					else
						x = ss.dup
						x.pin align, rect, align
					end
					bitmap.blt(x.x, x.y, bmp, srect)
					bmp.dispose
					Rect.new(x.x, x.y, srect.width, srect.height)
				end

			end
			def self.align(content)
				if content.is_a?(Hash)
					if align=content[:align]
						return align
					end
				end
				SD::Context.current.align 
			rescue
				5
			end 
			def self.get_bmp(content)
				content[:src]
			end
		end


	end
end
