require 'ext'
require 'ver'

class Archive < ExternalWrapper
	def self.init
		self.find ["libarchive2.dll", "libarchive-2.dll"] #GnuWin32 name(BSD), Mingw name(GPL)
	end
	init
	CLASS = self
	def initialize(filename)
		@entry = "\0"*4
		@read  = CLASS[:archive_read_new][]
		@data = {}
		CLASS[:archive_read_support_compression_all][@read]
		CLASS[:archive_read_support_format_all][@read]
		CLASS[:archive_read_open_filename][@read, Seiran20.to_mb(Seiran20.to_wc(filename),0).chomp("\0"), 1024*256]
		while CLASS[:archive_read_next_header][@read, @entry] == 0
			@ent = @entry.unpack('L').first
			name = CLASS[:archive_entry_pathname][@ent]
			name = name == 0 ? "(null)" : Seiran20.readstr(name)
			size = CLASS[:archive_entry_size][@ent]
			@data[name] = "\0"*size
			CLASS[:archive_read_data][@read, @data[name], size]
		end
        end
	attr_accessor :data
end