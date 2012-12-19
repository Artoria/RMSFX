=begin
# 
# Created by Hana Seiran 
#
# Documentation by Hana Seiran
#

Lisense:

Copyright (c) 2012, Seiran
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
   This product includes software developed by Seiran.

THIS SOFTWARE IS PROVIDED BY Seiran ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Seiran BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end


module CocoSimple::SubWorld::FontSet
        attr_accessor :name, :size, :color, :bold, :italic
        attr_accessor :shadow, :outline
        VERSION = "SubWorld Font 1.0"
        def setdefaultfont(stream = nil)
                stream ||= @stream
                stream << %Q{##{VERSION} setdefaultfont\n}
                stream << %Q{Font.default_name    = [#{@name.inspect}]\n} if @name != nil
                stream << %Q{Font.default_size    =  #{@size.inspect}\n} if @size != nil
                stream << %Q{Font.default_color   =  Color.new#{@color.inspect}\n}    if !@color.nil?
                stream << %Q{Font.default_bold    =  #{@bold.inspect}\n} if @bold!=nil
                stream << %Q{Font.default_italic  =  #{@italic.inspect}\n} if @italic !=nil
                
                if @version == :rmxp
                        if @shadow != nil or @outline != nil
                                #warn not supported
                        end
                else
                        stream << %Q{Font.default_shadow  =  #{@shadow.inspect}\n} if @shadow !=nil
                        stream << %Q{Font.default_outline  =  #{@outline.inspect}\n} if @outline !=nil
                end
        end
end

module CocoSimple::SubWorld::FontMaker
        attr_accessor :name, :size, :color, :bold, :italic
        attr_accessor :shadow, :outline
        VERSION = "SubWorld Font 1.0"
        def makefont(name, charset, stream = nil) #charset as byte
                x = Bitmap.new(512, 2048)
                x.font.name   = @name if @name != nil
                x.font.size   = @size if @size != nil
                x.font.color  = Color.new(255,0,0,255)
                x.font.bold   = @bold if @bold != nil
                x.font.italic = @italic if @italic != nil
                info = Artoria.new
                cx , cy = 0, 0
                mdy = 0
                rx, ry = 0, 0
                charset.split(//).each{|ch|
                        rect = x.text_size(ch)
                        dx, dy = rect.width, rect.height
                        if cx + dx > x.width
                                cx = 0
                                cy += mdy
                                mdy = 0
                        else
                                mdy = [mdy, dy].max
                        end
                        rx = [rx, cx + dx].max
                        ry = [ry, cy + dy].max
                        info[ch] = [cx, cy, dx, dy]
                        x.draw_text(cx, cy, dx, dy, ch)
                        cx += dx
                }
                rx = rx + 32 - rx % 32
                y = Bitmap.new(rx, ry)
                y.blt(0, 0, x, y.rect, 255)
                info["__w__"]=y.width
                info["__h__"]=y.height
                info["__bitmap__"] = y.addr[y.width*y.height*4]
                info.saveto(name)
                stream << %Q{##{VERSION} makefont #{name}\n}
        end
end


class CocoSimple::SubWorld::Font
        include CocoSimple::SubWorld::FontSet
        include CocoSimple::SubWorld::FontMaker
        def initialize(version = :rmxp, stream = nil)
                @stream  = stream
                @version = version
        end
end
