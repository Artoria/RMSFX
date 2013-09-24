SD::Layout.constants.each{|a|
        x = SD::Layout.const_get a
	next unless x.to_s[/^SD::Layout::/]
	name = x.to_s.sub(/^SD::Layout::/){}.downcase
	SD::Context.class_eval %{
		def #{name} args
			push_layout SD::Layout.new(#{x}, args)
			yield if block_given?
			pop_layout
		end
	}
}

SD::Dust.constants.each{|a|
        x = SD::Dust.const_get a
	next unless x.to_s[/^SD::Dust::/]
	name = x.to_s.sub(/^SD::Dust::/){}.downcase
	SD::Context.class_eval %{
		def #{name} arg
			@layout_stack[-1].push(q = SD::Dust.new(arg, #{x}))
		        q.id = @id
			self.object[@id] = q if @id
			@id = nil
		end
	}
}
