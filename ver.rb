require 's20'
module VER
 XP = VX = VA = RGSS_V = RGSS = RGSS2 = RGSS3 = false
 case Seiran20::ID_RGSS
  when /RGSS1/
   XP   = 1  
   RGSS_V = 1
  when /RGSS2/
   VX   = 1  
   RGSS_V = 2
   RGSS2 = 1
  when /RGSS3/
   VA   = 1  
   RGSS_V = 3
   RGSS3 = 1
 end
end
