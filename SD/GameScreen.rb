module SD
	module GameScreen
		def self.all
			SD::Rect.new(0, 0, Graphics.width, Graphics.height)
		rescue
			SD::Rect.new(0, 0, 640, 480)
		end
	end
end
