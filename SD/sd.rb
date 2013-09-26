SD::Layout.constants.each{|a|
        x = SD::Layout.const_get a
	next unless x.to_s[/^SD::Layout::/]
	name = (name2=x.to_s.sub(/^SD::Layout::/){}).downcase
	SD::Context.class_eval %{
		def #{name} args
			push_layout(q = SD::Layout.new(self.namespace::Layout::#{name2}, args))
			q.id = @id
			self.object[@id] = q if @id
			@id = nil
			yield if block_given?
			pop_layout
		end
	}
}

SD::Dust.constants.each{|a|
        x = SD::Dust.const_get a
	next unless x.to_s[/^SD::Dust::/]
	name = (name2=x.to_s.sub(/^SD::Dust::/){}).downcase
	SD::Context.class_eval %{
		def #{name} arg, &b
			@layout_stack[-1].push(q = SD::Dust.new(arg, self.namespace::Dust::#{name2}, &b))
		        q.id = @id
			self.object[@id] = q if @id
			@id = nil
		end
	}
}
