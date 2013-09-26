require 's20'

module OS
        GetDC            = Seiran20.api("user32", "GetDC")
        ReleaseDC        = Seiran20.api("user32", "ReleaseDC")
        EnumFontFamilies = Seiran20.api("gdi32", "EnumFontFamiliesW")
        def self.fonts
                hdc = GetDC.call(Seiran20.hwnd)
                fontNames = []
                callback = Seiran20.callback{|lf,pf,tp,lp|fontNames << Seiran20.to_mb(Seiran20.readwstr(lf+28)).chomp("\0");1;}
                EnumFontFamilies.call hdc, 0, callback, 0
                ReleaseDC.call hdc
                fontNames
        end


end
        
