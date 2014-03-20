class ::Window
  Actives = []
  unless method_defined?(:rmsfx_active=)
    alias :rmsfx_active= :active=
    alias :rmsfx_init :initialize
    def initialize(*a)
      rmsfx_init(*a)
      self.active = self.active
    end
    def active=(value)
      if value 
        Actives.push self 
      else
        Actives.delete self
      end
      self.rmsfx_active = value
    end
  end
end