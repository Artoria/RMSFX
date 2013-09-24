module Prelude
  class FFI < Roost::Dynamic::Dyn
    
  end
  class DFFI < FFI
    def method_missing(sym, *args)
            x = sym.to_s
              par = args.inject(""){|str, i|
                  if i.is_a?(Integer)
                    str += "L"
                  elsif i.is_a?(String)
                    str += "p"
                  end
              }
              a ||= guess(x, par)
              a ||= guess("#{x}@#{par.length*4}", par)
              a ||= guess("_#{x}", par)
              a ||= guess("_#{x}@#{par.length*4}", par)
              a.call(*args)
    end
  end
end