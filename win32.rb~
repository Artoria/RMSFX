require 's20'

module OS
        GetDC            = Seiran20.api("user32", "GetDC")
        ReleaseDC        = Seiran20.api("user32", "ReleaseDC")
        EnumFontFamilies = Seiran20.api("gdi32", "EnumFontFamiliesA")
        def self.fonts
                hdc = GetDC.call(Seiran20.hwnd)
                fontNames = []
                callback = Seiran20.callback{|lf,pf,tp,lp|fontNames << Seiran20.to_mb(Seiran20.to_wc(Seiran20.readstr(lf+28), 0)).chomp("\0");1;}
                EnumFontFamilies.call hdc, 0, callback, 0
                ReleaseDC.call hdc
                fontNames
        end


end
        
