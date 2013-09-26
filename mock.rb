class Mock
	Output = nil
	def initialize(*a, &b)
		Output.write  "#{inspect} Initialize with #{a.inspect} &#{b.inspect}\n"
	end
	def method_missing(sym, *args,&b)
		if sym.to_s[/=$/]
			Output.write "#{inspect} set #{sym} to #{args[0].inspect}\n"
		else
			Output.write "#{inspect} call #{([sym] + args).inspect} &#{b.inspect}\n"
		end
		nil
	end
end
