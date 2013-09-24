module SD
  module Mixin
    module Text
      attr_accessor :text_margin, :text_margin_h, :text_margin_w
      def push_font opt
        x = Font.new
        self.bitmap.font.methods.grep(/[a-z]=$/){|method| x.send method, self.bitmap.font.send(method.to_s.chomp("="))}
        opt.each do |k, v| x.send "#{k}=", v end
        (@font_stack ||= []).push self.bitmap.font.clone
        self.bitmap.font = x
      end
      def pop_font
        self.bitmap.font = (@font_stack||= [self.bitmap.font]).pop
      end
      def draw_text(*args)
        case args.length
          when 5 then x, y, w, h, str, align = args + [0]; rect = SD::Parent.new x, y, w, h
          when 6 then x, y, w, h, str, align = args; rect = SD::Parent.new x, y, w, h
          when 2 then pos, str, align = args + [0]
          when 3 then pos, str, align = args
        end
        rect = pos
        if (1..9) === pos
          w = self.bitmap.text_size str
          wadd = (self.text_margin || 0) + (self.text_margin_w || 0)
          hadd = (self.text_margin || 0) + (self.text_margin_h || 0)
          rect = special_rect pos, Parent.new(wadd, hadd, w.width + wadd, w.height + hadd)
          rect.dock pos
        end
        self.bitmap.draw_text(rect, str, align)
      end
    end
  end
end