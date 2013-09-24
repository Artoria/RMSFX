#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2006-2009 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory

module Metasm
module Gui
class Graph
	# one box, has a text, an id, and a list of other boxes to/from
	class Box
		attr_accessor :id, :x, :y, :w, :h
		attr_accessor :to, :from # other boxes linked (arrays)
		attr_accessor :content
		attr_accessor :direct_to
		def initialize(id, content=nil)
			@id = id
			@x = @y = @w = @h = 0
			@to, @from = [], []
			@content = content
		end
		def [](a) @content[a] end
		#def inspect ; puts caller ; "#{Expression[@id] rescue @id.inspect}" end
	end

	attr_accessor :id, :box, :box_id, :root_addrs, :view_x, :view_y, :keep_split
	def initialize(id)
		@id = id
		@root_addrs = []
		@view_x = @view_y = -0xfff_ffff
		clear
	end

	# empty @box
	def clear
		@box = []
		@box_id = {}
	end

	# link the two boxes (by id)
	def link_boxes(id1, id2)
		raise "unknown index 1 #{id1}" if not b1 = @box_id[id1]
		raise "unknown index 2 #{id2}" if not b2 = @box_id[id2]
		b1.to   |= [b2]
		b2.from |= [b1]
	end

	# creates a new box, ensures id is not already taken
	def new_box(id, content=nil)
		raise "duplicate id #{id}" if @box_id[id]
		b = Box.new(id, content)
		@box << b
		@box_id[id] = b
		b
	end

	# returns the [x1, y1, x2, y2] of the rectangle encompassing all boxes
	def boundingbox
		minx = @box.map { |b| b.x }.min.to_i
		miny = @box.map { |b| b.y }.min.to_i
		maxx = @box.map { |b| b.x + b.w }.max.to_i
		maxy = @box.map { |b| b.y + b.h }.max.to_i
		[minx, miny, maxx, maxy]
	end

	# position known box patterns recursively (lines, columns, if/end)
	def pattern_layout
		nil while pattern_layout_col or pattern_layout_line or pattern_layout_ifend
	end

	# a -> b -> c -> d (no other in/outs)
	def pattern_layout_col
		# find head
		return if not head = @groups.find { |g|
			g.to.length == 1 and
			g.to[0].from.length == 1 and
			(g.from.length != 1 or g.from[0].to.length != 1)
		}

		# find full sequence
		ar = [head]
		while head.to.length == 1 and head.to[0].from.length == 1
			head = head.to[0]
			ar << head
		end

		# move boxes inside this group
		maxw = ar.map { |g| g.w }.max
		if ar.last.to.include? ar.first
			# ar is a loop: shift whole array to
			#  make place for the arrow going up
			maxw += 20
			dx = 10
		else dx = 0
		end
		fullh = ar.inject(0) { |h, g| h + g.h }
		cury = -fullh/2
		ar.each { |g|
			dy = cury - g.y
			g.content.each { |b| b.x += dx ; b.y += dy }
			cury += g.h
		}

		# create remplacement group
		newg = Box.new(nil, ar.map { |g| g.content }.flatten)
		newg.w = maxw
		newg.h = fullh
		newg.x = -newg.w/2
		newg.y = -newg.h/2
		newg.from = ar.first.from - ar
		newg.to = ar.last.to - ar
		# fix xrefs
		newg.from.each { |g| g.to -= ar ; g.to << newg }
		newg.to.each { |g| g.from -= ar ; g.from << newg }
		# fix @groups
		@groups[@groups.index(head)] = newg
		@groups -= ar

		true
	end

	# a -> [b, c, d] -> e
	def pattern_layout_line
		# find head
		ar = []
		@groups.each { |g|
			if g.from.length == 1 and g.to.length <= 1 and g.from.first.to.length > 1
				ar = g.from.first.to.find_all { |gg| gg.from == g.from and gg.to == g.to }
			elsif g.from.empty? and g.to.length == 1 and g.to.first.from.length > 1
				ar = g.to.first.from.find_all { |gg| gg.from == g.from and gg.to == g.to }
			else ar = []
			end
			break if ar.length > 1
		}
		return if ar.length <= 1

		# move boxes inside this group
		ar = ar.sort_by { |g| -g.h }
		maxh = ar.last.h
		fullw = ar.inject(0) { |w, g| w + g.w }
		curx = -fullw/2
		ar.each { |g|
			# if no to, put all boxes at bottom ; if no from, put them at top
			case [g.from.length, g.to.length]
			when [1, 0]; dy = (g.h - maxh)/2
			when [0, 1]; dy = (maxh - g.h)/2
			else dy = 0
			end

			dx = curx - g.x
			g.content.each { |b| b.x += dx ; b.y += dy }
			curx += g.w
		}
		# add a 'margin-top' proportionnal to the ar width
		# this gap should be relative to the real boxes and not possible previous gaps when
		# merging lines (eg long line + many if patterns -> dont duplicate gaps)
		boxen = ar.map { |g| g.content }.flatten
		realh = boxen.map { |g| g.y + g.h }.max - boxen.map { |g| g.y }.min
		if maxh < realh + fullw/4
			maxh = realh + fullw/4
		end

		# create remplacement group
		newg = Box.new(nil, ar.map { |g| g.content }.flatten)
		newg.w = fullw
		newg.h = maxh
		newg.x = -newg.w/2
		newg.y = -newg.h/2
		newg.from = ar.first.from
		newg.to = ar.first.to
		# fix xrefs
		newg.from.each { |g| g.to -= ar ; g.to << newg }
		newg.to.each { |g| g.from -= ar ; g.from << newg }
		# fix @groups
		@groups[@groups.index(ar.first)] = newg
		@groups -= ar

		true
	end

	# a -> b -> c & a -> c
	def pattern_layout_ifend
		# find head
		return if not head = @groups.find { |g|
			g.to.length == 2 and
			((g.to[0].to.length == 1 and g.to[0].to[0] == g.to[1] and g.to[0].from.length == 1) or
			 (g.to[1].to.length == 1 and g.to[1].to[0] == g.to[0] and g.to[1].from.length == 1))
		}

		if head.to[0].from.length == 1
			ten = head.to[0]
		else
			ten = head.to[1]
		end

		# stuff 'then' inside the 'if'
		# move 'if' up, 'then' down
		head.content.each { |g| g.y -= ten.h/2 }
		ten.content.each { |g| g.y += head.h/2 }
		head.h += ten.h
		head.y -= ten.h/2

		# widen 'if'
		dw = 2*ten.w - head.w
		if dw > 0
			# need to widen head to fit ten
			head.w += dw
			head.x -= dw/2
		end

		# merge
		ten.content.each { |g| g.x += -ten.x }
		head.content.concat ten.content
		head.to.delete ten
		head.to[0].from.delete ten

		# XXX now head is too wide on the left side

		@groups.delete ten

		true

	end

	# find the minimal set of nodes from which we can reach all others
	# this is done *before* removing cycles in the graph
	# stored as having an order of 0
	def find_roots
		roots = @groups.find_all { |g| g.from.empty? }
		roots << @groups.first if roots.empty? and @groups.first
		# tentative @order
		o = {}
		todo = []
		roots.each { |g|
			o[g] = 0
			todo |= g.to
		}
		loop do
			# order nodes from the tentative roots
			while n = todo.find { |g| g.from.all? { |gg| o[gg] } } ||
				  todo.sort_by { |g| g.from.map { |gg| o[gg] }.compact.max }.first	# cycle heads
				todo.delete n
				o[n] = n.from.map { |g| o[g] }.compact.max + 1
				todo |= n.to.find_all { |g| not o[g] }
			end
			# todo empty at this point
			break if o.length >= @groups.length

			if rt = roots.find { |g| g.from.find { |gg| not o[gg] } } ||
					@groups.find_all { |g| o[g] and g.from.find { |gg| not o[gg] } }.sort_by { |g| o[g] }.first
				# if we picked a root in the middle of the graph, try to go up
				utodo = rt.from.find_all { |g| not o[g] }
				while n = utodo.find { |g| g.to.all? { |gg| o[gg] } } ||
					  utodo.sort_by { |g| g.to.map { |gg| o[gg] }.compact.min }.first
					utodo.delete n
					o[n] = n.to.map { |g| o[g] }.compact.min - 1
					utodo |= n.from.find_all { |g| not o[g] }
					todo |= n.to.find_all { |g| not o[g] }
				end
				# setup todo for next fwd iteration
				todo = todo.find_all { |g| g.from.find { |gg| o[gg] } }
			else
				# disjoint graph, start over from there
				roots = [@groups.find { |g| not o[g] }]
				roots.each { |g|
					o[g] = 0
					todo |= g.to.find_all { |gg| not o[gg] }
				}
			end
		end

		# now all nodes have a relative order, which may be negative
		# extract real roots from that (root iff no from with lower order)
		roots = @groups.find_all { |g| not g.from.find { |gg| o[gg] < o[g] } }
		# recompute real order from these roots
		@order = {}
		todo = []
		roots.each { |g|
			@order[g] = 0
			todo |= g.to
		}
		todo -= roots
		until todo.empty?
			if not n = todo.find { |g| g.from.all? { |gg| @order[gg] } }
				# try to find cycle heads, starting from highest order parent
				# take additionnal steps to avoid selecting a top node that should be
				# child of some other loop
				# eg 1 -> 4 ; 1 -> 2 -> <cycle> -> 4  => start with the cycle, and not 4
				cheads = todo.sort_by { |g| g.from.map { |gg| @order[gg] }.compact.max || @groups.length }
				n = cheads.first
				cheads.each_with_index { |g, i|
					next if cheads[i+1..-1].find { |gg|
						can_find_path(gg, g) and not can_find_path(g, gg)
					}
					n = g
					break
				}
			end
			todo.delete n
			@order[n] = n.from.map { |g| @order[g] }.compact.max + 1
			todo |= n.to.find_all { |g| not @order[g] }
		end
		raise if @order.length != @groups.length
	end

	# checks if there is a path from src to dst
	def can_find_path(src, dst)
		todo = [src]
		done = {}
		while g = todo.pop
			return true if g == dst
			todo.concat g.to unless done[g]
			done[g] = true
		end
	end

	# remove looping edges from @groups, order the boxes in layers, find the roots of the graph, create dummy groups along long edges
	def maketree
		find_roots

		# now we have the roots and node orders
		#  revert cycling edges - o(chld) < o(parent)
		#  expand long edges    - o(chld) > o(parent)+1
		newemptybox = lambda { b = Box.new(nil, []) ; b.x = -8 ; b.y = -9 ; b.w = 16 ; b.h = 18 ; @groups << b ; b }
		newboxo = {}
		@order.each_key { |g|
			og = @order[g] || newboxo[g]
			g.to.dup.each { |gg|
				ogg = @order[gg] || newboxo[gg]
				if ogg < og
					# cycling edge, revert & may expand
					sq = [gg]
					if ogg < og-1
						(og - 1 - ogg).times { |i| sq << newemptybox[] }
					end
					sq << g
					g.from.delete gg
					gg.to.delete g
					newboxo[gg] ||= @order[gg]
					sq.inject { |g1, g2|
						g1.to |= [g2]
						g2.from |= [g1]
						# need separate hash to avoid updating @order in its #each_key
						newboxo[g2] = newboxo[g1]+1
						g2
					}
					raise if newboxo[g] != og
				elsif ogg > og+1
					# long edge, expand
					sq = [g]
					(ogg - 1 - og).times { |i| sq << newemptybox[] }
					sq << gg
					gg.from.delete g
					g.to.delete gg
					newboxo[g] ||= @order[g]
					sq.inject { |g1, g2|
						g1.to |= [g2]
						g2.from |= [g1]
						newboxo[g2] = newboxo[g1]+1
						g2
					}
					raise if newboxo[gg] != ogg
				end
			}
		}
		@order.update newboxo

		# @layers[o] = [list of nodes of order o]
		@layers = []
		@groups.each { |g|
			(@layers[@order[g]] ||= []) << g
		}
	end

	# place boxes in a good-looking layout
	def auto_arrange_init(list=@box)
		# groups is an array of box groups
		# all groups are centered on the origin
		h = {}	# { group => box }
		@groups = list.map { |b|
			b.x = -b.w/2
			b.y = -b.h/2
			g = Box.new(nil, [b])
			g.x = b.x - 8
			g.y = b.y - 9
			g.w = b.w + 16
			g.h = b.h + 18
			h[b] = g
			g
		}

		# init group.to/from
		# must always point to something that is in the 'groups' array
		# no self references
		# a box is in one and only one group in 'groups'
		@groups.each { |g|
			g.to   = g.content.first.to.map   { |t| h[t] if t != g }.compact
			g.from = g.content.first.from.map { |f| h[f] if f != g }.compact
		}

		pattern_layout

		maketree
		return if @layers.empty?

		# TODO layout disjoint graphs distinctly ?

		# widest layer width
		maxlw = @layers.map { |l| l.inject(0) { |ll, g| ll + g.w } }.max

		# center the 1st layer boxes on a segment that large
		x0 = -maxlw/2.0
		curlw = @layers[0].inject(0) { |ll, g| ll + g.w }
		dx0 = (maxlw - curlw) / (2.0*@layers[0].length)
		@layers[0].each { |g|
			x0 += dx0
			g.x = x0
			x0 += g.w + dx0
		}
	end

	def auto_arrange_step
		return if @layers.empty?

		# at this point, the goal is to reorder the most populated layer the best we can, and
		# move other layers' boxes accordingly

		maxlw = @layers.map { |l| l.inject(0) { |ll, g| ll + g.w } }.max
		@layers[1..-1].each { |l|
			# for each subsequent layer, reorder boxes based on their ties with the previous layer
			i = 0
			l.replace l.sort_by { |g|
				# we know g.from is not empty (g would be in @layer[0])
				medfrom = g.from.inject(0.0) { |mx, gg| mx + (gg.x + gg.w/2.0) } / g.from.length
				# on ties, keep original order
				[medfrom, i]
			}
			# now they are reordered, update their #x accordingly
			# evenly distribute them in the layer
			x0 = -maxlw/2.0
			curlw = l.inject(0) { |ll, g| ll + g.w }
			dx0 = (maxlw - curlw) / (2.0*l.length)
			l.each { |g|
				x0 += dx0
				g.x = x0
				x0 += g.w + dx0
			}
		}

		@layers[0...-1].reverse_each { |l|
			# for each subsequent layer, reorder boxes based on their ties with the previous layer
			i = 0
			l.replace l.sort_by { |g|
				if g.to.empty?
					# TODO floating end
					medfrom = 0
				else
					medfrom = g.to.inject(0.0) { |mx, gg| mx + (gg.x + gg.w/2.0) } / g.to.length
				end
				# on ties, keep original order
				[medfrom, i]
			}
			# now they are reordered, update their #x accordingly
			x0 = -maxlw/2.0
			curlw = l.inject(0) { |ll, g| ll + g.w }
			dx0 = (maxlw - curlw) / (2.0*l.length)
			l.each { |g|
				x0 += dx0
				g.x = x0
				x0 += g.w + dx0
			}
		}

		# now the boxes are (hopefully) sorted correctly
		# position them according to their ties with prev/next layer
		# from the maxw layer (positionning = packed), propagate adjacent layers positions
		maxidx = (0..@layers.length).find { |i| l = @layers[i] ; l.inject(0) { |ll, g| ll + g.w } == maxlw }
		# list of layer indexes to walk
		ilist = []
		ilist.concat((maxidx+1...@layers.length).to_a) if maxidx < @layers.length-1
		ilist.concat((0..maxidx-1).to_a.reverse) if maxidx > 0
		ilist.each { |i|
			l = @layers[i]
			curlw = l.inject(0) { |ll, g| ll + g.w }
			# left/rightmost acceptable position for the current box w/o overflowing on the right side
			minx = -maxlw/2.0
			maxx = minx + (maxlw-curlw)
			l.each { |g|
				ref = (i < maxidx) ? g.to : g.from
				# TODO elastic positionning around the ideal position
				# (g and g+1 may have the same med, then center both on it)
				if ref.empty?
					g.x = (minx+maxx)/2
				else
					# center on the outline of rx
					# may want to center on rx center's center ?
					rx = ref.sort_by { |gg| gg.x }
					med = (rx[0].x + rx[-1].x + rx[-1].w - g.w) / 2.0
					g.x = [[med, minx].max, maxx].min
				end
				minx = g.x + g.w
				maxx += g.w
			}
		}
		nil
	end

	def auto_arrange_post
		# vertical: just center each box on its layer
		y0 = 0
		@layers.each { |l|
			hmax = l.map { |g| g.h }.max
			l.each { |g|
				g.y = y0 + (hmax - g.h)/2
			}
			y0 += hmax
		}

		# actually move boxes inside the groups
		@groups.each { |g|
			dx = (g.x + g.w/2).to_i
			dy = (g.y + g.h/2).to_i
			g.content.each { |b|
				b.x += dx
				b.y += dy
			}
		}

		# TODO
		# energy-minimal positionning of boxes from this basic layout
		# avoid arrow confusions
	end

	def auto_arrange_boxes
		auto_arrange_init
		nil while @groups.length > 1 and auto_arrange_step
		auto_arrange_post
		@groups = []
	end

	# gives a text representation of the current graph state
	def dump_layout(groups=@groups)
		groups.map { |g| "#{groups.index(g)} -> #{g.to.map { |t| groups.index(t) }.sort.inspect}" }
	end
end





class GraphViewWidget < DrawableWidget
	attr_accessor :dasm, :caret_box, :curcontext, :zoom, :margin
	# bool, specifies if we should display addresses before instrs
	attr_accessor :show_addresses

	def initialize_widget(dasm, parent_widget)
		@dasm = dasm
		@parent_widget = parent_widget

		@show_addresses = false

		@caret_box = nil
		@selected_boxes = []
		@shown_boxes = []
		@mousemove_origin = @mousemove_origin_ctrl = nil
		@curcontext = Graph.new(nil)
		@want_focus_addr = nil
		@margin = 8
		@zoom = 1.0
		@default_color_association = { :background => :paleblue, :hlbox_bg => :palegrey, :box_bg => :white,
				:text => :black, :arrow_hl => :red, :comment => :darkblue, :address => :darkblue,
				:instruction => :black, :label => :darkgreen, :caret => :black, :hl_word => :palered,
				:cursorline_bg => :paleyellow, :arrow_cond => :darkgreen, :arrow_uncond => :darkblue,
			       	:arrow_direct => :darkred }
		# @othergraphs = ?	(to keep user-specified formatting)
	end

	def view_x; @curcontext.view_x; end
	def view_x=(vx); @curcontext.view_x = vx; end
	def view_y; @curcontext.view_y; end
	def view_y=(vy); @curcontext.view_y = vy; end

	def resized(w, h)
		redraw
	end

	def find_box_xy(x, y)
		x = view_x+x/@zoom
		y = view_y+y/@zoom
		@shown_boxes.to_a.reverse.find { |b| b.x <= x and b.x+b.w > x and b.y <= y-1 and b.y+b.h > y+1 }
	end

	def mouse_wheel_ctrl(dir, x, y)
		case dir
		when :up
			if @zoom < 100
				oldzoom = @zoom
				@zoom *= 1.1
				@zoom = 1.0 if (@zoom-1.0).abs < 0.05
				@curcontext.view_x += (x / oldzoom - x / @zoom)
				@curcontext.view_y += (y / oldzoom - y / @zoom)
			end
		when :down
			if @zoom > 1.0/1000
				oldzoom = @zoom
				@zoom /= 1.1
				@zoom = 1.0 if (@zoom-1.0).abs < 0.05
				@curcontext.view_x += (x / oldzoom - x / @zoom)
				@curcontext.view_y += (y / oldzoom - y / @zoom)
			end
		end
		redraw
	end

	def mouse_wheel(dir, x, y)
		case dir
		when :up; @curcontext.view_y -= height/4 / @zoom
		when :down; @curcontext.view_y += height/4 / @zoom
		end
		redraw
	end

	def mousemove(x, y)
		return if not @mousemove_origin

		dx = (x - @mousemove_origin[0])/@zoom
		dy = (y - @mousemove_origin[1])/@zoom
		@mousemove_origin = [x, y]
		if @selected_boxes.empty?
			@curcontext.view_x -= dx ; @curcontext.view_y -= dy
		else
			@selected_boxes.each { |b| b.x += dx ; b.y += dy }
		end
		redraw
	end

	def mouserelease(x, y)
		mousemove(x, y)
		@mousemove_origin = nil

		if @mousemove_origin_ctrl
			x1 = view_x + @mousemove_origin_ctrl[0]/@zoom
			x2 = x1 + (x - @mousemove_origin_ctrl[0])/@zoom
			x1, x2 = x2, x1 if x1 > x2
			y1 = view_y + @mousemove_origin_ctrl[1]/@zoom
			y2 = y1 + (y - @mousemove_origin_ctrl[1])/@zoom
			y1, y2 = y2, y1 if y1 > y2
			@selected_boxes |= @curcontext.box.find_all { |b| b.x >= x1 and b.x + b.w <= x2 and b.y >= y1 and b.y + b.h <= y2 }
			redraw
			@mousemove_origin_ctrl = nil
		end
	end

	def click_ctrl(x, y)
		if b = find_box_xy(x, y)
			if @selected_boxes.include? b
				@selected_boxes.delete b
			else
				@selected_boxes << b
			end
			redraw
		else
			@mousemove_origin_ctrl = [x, y]
		end
	end

	def click(x, y)
		@mousemove_origin = [x, y]
		if b = find_box_xy(x, y)
			@selected_boxes = [b] if not @selected_boxes.include? b
			@caret_box = b
			@caret_x = (view_x+x/@zoom-b.x-1).to_i / @font_width
			@caret_y = (view_y+y/@zoom-b.y-1).to_i / @font_height
			update_caret
		else
			@selected_boxes = []
			@caret_box = nil
		end
		redraw
	end

	def setup_contextmenu(b, m)
		cm = new_menu
		addsubmenu(cm, 'copy _word') { clipboard_copy(@hl_word) if @hl_word }
		addsubmenu(cm, 'copy _line') { clipboard_copy(@caret_box[:line_text_col][@caret_y].map { |ss, cc| ss }.join) }
		addsubmenu(cm, 'copy _box')  {
			sb = @selected_boxes
			sb = [@curbox] if sb.empty?
			clipboard_copy(sb.map { |ob| ob[:line_text_col].map { |s| s.map { |ss, cc| ss }.join + "\r\n" }.join }.join("\r\n"))
		}	# XXX auto \r\n vs \n
		addsubmenu(m, '_clipboard', cm)
		addsubmenu(m, 'clone _window') { @parent_widget.clone_window(@hl_word, :graph) }
	end

	# if the target is a call to a subfunction, open a new window with the graph of this function (popup)
	def rightclick(x, y)
		if b = find_box_xy(x, y) and @zoom >= 0.90 and @zoom <= 1.1
			click(x, y)
			@mousemove_origin = nil
			m = new_menu
			setup_contextmenu(b, m)
			if @parent_widget.respond_to?(:extend_contextmenu)
				@parent_widget.extend_contextmenu(self, m, @caret_box[:line_address][@caret_y])
			end
			popupmenu(m, x, y)
		end
	end

	def doubleclick(x, y)
		if b = find_box_xy(x, y)
			@mousemove_origin = nil
			if @hl_word and @zoom >= 0.90 and @zoom <= 1.1
				@parent_widget.focus_addr(@hl_word)
			else
				@parent_widget.focus_addr((b[:addresses] || b[:line_address]).first)
			end
		elsif doubleclick_check_arrow(x, y)
		elsif @zoom == 1.0
			zoom_all
		else
			@curcontext.view_x += (x/@zoom - x)
			@curcontext.view_y += (y/@zoom - y)
			@zoom = 1.0
		end
		redraw
	end

	# check if the user clicked on the beginning/end of an arrow, if so focus on the other end
	def doubleclick_check_arrow(x, y)
		return if @margin*@zoom < 2
		x = view_x+x/@zoom
		y = view_y+y/@zoom
		sx = nil
		if bt = @shown_boxes.to_a.reverse.find { |b|
			y >= b.y+b.h-1 and y <= b.y+b.h-1+@margin+2 and
			sx = b.x+b.w/2 - b.to.length/2 * @margin/2 and
		       	x >= sx-@margin/2 and x <= sx+b.to.length*@margin/2	# should be margin/4, but add a little comfort margin
		}
			idx = (x-sx+@margin/4).to_i / (@margin/2)
			idx = 0 if idx < 0
			idx = bt.to.length-1 if idx >= bt.to.length
			if bt.to[idx]
				if @parent_widget
					@parent_widget.focus_addr bt.to[idx][:line_address][0]
				else
					focus_xy(bt.to[idx].x, bt.to[idx].y)
				end
			end
			true
		elsif bf = @shown_boxes.to_a.reverse.find { |b|
			y >= b.y-@margin-2 and y <= b.y and
			sx = b.x+b.w/2 - b.from.length/2 * @margin/2 and
		       	x >= sx-@margin/2 and x <= sx+b.from.length*@margin/2
		}
			idx = (x-sx+@margin/4).to_i / (@margin/2)
			idx = 0 if idx < 0
			idx = bf.from.length-1 if idx >= bf.from.length
			if bf.from[idx]
				if @parent_widget
					@parent_widget.focus_addr bf.from[idx][:line_address][-1]
				else
					focus_xy(bt.from[idx].x, bt.from[idx].y)
				end
			end
			true
		end
	end

	# update the zoom & view_xy to show the whole graph in the window
	def zoom_all
		minx, miny, maxx, maxy = @curcontext.boundingbox
		minx -= @margin
		miny -= @margin
		maxx += @margin
		maxy += @margin

		@zoom = [width.to_f/(maxx-minx), height.to_f/(maxy-miny)].min
		@zoom = 1.0 if @zoom > 1.0 or (@zoom-1.0).abs < 0.1
		@curcontext.view_x = minx + (maxx-minx-width/@zoom)/2
		@curcontext.view_y = miny + (maxy-miny-height/@zoom)/2
		redraw
	end

	def paint
		update_graph if @want_update_graph
		if @want_focus_addr and @curcontext.box.find { |b_| b_[:line_address].index(@want_focus_addr) }
			focus_addr(@want_focus_addr, false)
			@want_focus_addr = nil
			#zoom_all
		end

		@curcontext.box.each { |b|
			# reorder arrows so that endings do not overlap
			b.to = b.to.sort_by { |bt| bt.x+bt.w/2 }
			b.from = b.from.sort_by { |bt| bt.x+bt.w/2 }
		}
		# arrows drawn first to stay under the boxes
		# XXX precalc ?
		@curcontext.box.each { |b|
			b.to.each { |bt| paint_arrow(b, bt) }
		}

		@shown_boxes = []
		w_w = width
	       	w_h = height
		@curcontext.box.each { |b|
			next if b.x >= view_x+w_w/@zoom or b.y >= view_y+w_h/@zoom or b.x+b.w <= view_x or b.y+b.h <= view_y
			@shown_boxes << b
			paint_box(b)
		}
	end

	def set_color_arrow(b1, b2)
		if b1 == @caret_box or b2 == @caret_box
			draw_color :arrow_hl
		elsif b1.to.length == 1
			draw_color :arrow_uncond
		elsif b1.direct_to == b2.id
			draw_color :arrow_direct
		else
			draw_color :arrow_cond
		end
	end

	def paint_arrow(b1, b2)
		x1 = x1o = b1.x+b1.w/2-view_x
		y1 = b1.y+b1.h-view_y
		x2 = x2o = b2.x+b2.w/2-view_x
		y2 = b2.y-1-view_y
		margin = @margin
		x1 += (-(b1.to.length-1)/2 + b1.to.index(b2)) * margin/2
		x2 += (-(b2.from.length-1)/2 + b2.from.index(b1)) * margin/2
		return if (y1+margin < 0 and y2 < 0) or (y1 > height/@zoom and y2-margin > height/@zoom)	# just clip on y
		margin, x1, y1, x2, y2, b1w, b2w, x1o, x2o = [margin, x1, y1, x2, y2, b1.w, b2.w, x1o, x2o].map { |v| v*@zoom }


		# straighten vertical arrows if possible
		if y2 > y1 and (x1-x2).abs <= margin
			if b1.to.length == 1
				x1 = x2
			elsif b2.from.length == 1
				x2 = x1
			end
		end

		set_color_arrow(b1, b2)
		if margin > 1
			# draw arrow tip
			draw_line(x1, y1, x1, y1+margin)
			draw_line(x2, y2-margin+1, x2, y2)
			draw_line(x2-margin/2, y2-margin/2, x2, y2)
			draw_line(x2+margin/2, y2-margin/2, x2, y2)
			y1 += margin
			y2 -= margin-1
		end
		if y2+margin >= y1-margin-1
			# straight vertical down arrow
			draw_line(x1, y1, x2, y2) if x1 != y1 or x2 != y2

		# else arrow up, need to sneak around boxes
		elsif x1o-b1w/2-margin >= x2o+b2w/2+margin	# z
			draw_line(x1, y1, x1o-b1w/2-margin, y1)
			draw_line(x1o-b1w/2-margin, y1, x2o+b2w/2+margin, y2)
			draw_line(x2o+b2w/2+margin, y2, x2, y2)
			draw_line(x1, y1+1, x1o-b1w/2-margin, y1+1) # double
			draw_line(x1o-b1w/2-margin+1, y1, x2o+b2w/2+margin+1, y2)
			draw_line(x2o+b2w/2+margin, y2+1, x2, y2+1)
		elsif x1+b1w/2+margin <= x2-b2w/2-margin	# invert z
			draw_line(x1, y1, x1o+b1w/2+margin, y1)
			draw_line(x1o+b1w/2+margin, y1, x2o-b2w/2-margin, y2)
			draw_line(x2o-b2w/2-margin, y2, x2, y2)
			draw_line(x1, y1+1, x1+b1w/2+margin, y1+1) # double
			draw_line(x1o+b1w/2+margin+1, y1, x2o-b2w/2-margin+1, y2)
			draw_line(x2o-b2w/2-margin, y2+1, x2, y2+1)
		else						# turn around
			x = (x1 <= x2 ? [x1o-b1w/2-margin, x2o-b2w/2-margin].min : [x1o+b1w/2+margin, x2o+b2w/2+margin].max)
			draw_line(x1, y1, x, y1)
			draw_line(x, y1, x, y2)
			draw_line(x, y2, x2, y2)
			draw_line(x1, y1+1, x, y1+1) # double
			draw_line(x+1, y1, x+1, y2)
			draw_line(x, y2+1, x2, y2+1)
		end
	end

	def set_color_boxshadow(b)
		draw_color :black
	end

	def set_color_box(b)
		if @selected_boxes.include? b
			draw_color :hlbox_bg
		else
			draw_color :box_bg
		end
	end

	def paint_box(b)
		set_color_boxshadow(b)
		draw_rectangle((b.x-view_x+3)*@zoom, (b.y-view_y+4)*@zoom, b.w*@zoom, b.h*@zoom)
		set_color_box(b)
		draw_rectangle((b.x-view_x)*@zoom, (b.y-view_y+1)*@zoom, b.w*@zoom, b.h*@zoom)

		# current text position
		x = (b.x - view_x + 1)*@zoom
		y = (b.y - view_y + 1)*@zoom
		w_w = (b.x - view_x + b.w - @font_width)*@zoom
		w_h = (b.y - view_y + b.h - @font_height)*@zoom
		w_h = height if w_h > height

		if @parent_widget and @parent_widget.bg_color_callback
			ly = 0
			b[:line_address].each { |a|
				if c = @parent_widget.bg_color_callback[a]
					draw_rectangle_color(c, (b.x-view_x)*@zoom, (1+b.y-view_y+ly*@font_height)*@zoom, b.w*@zoom, (@font_height*@zoom).ceil)
				end
				ly += 1
			}
		end

		if @caret_box == b
			draw_rectangle_color(:cursorline_bg, (b.x-view_x)*@zoom, (1+b.y-view_y+@caret_y*@font_height)*@zoom, b.w*@zoom, @font_height*@zoom)
		end

		return if @zoom < 0.99 or @zoom > 1.1
		# TODO dynamic font size ?

		# renders a string at current cursor position with a color
		# must not include newline
		render = lambda { |str, color|
			next if y >= w_h+2 or x >= w_w
			if @hl_word
				stmp = str
				pre_x = 0
				while stmp =~ @hl_word_re
					s1, s2 = $1, $2
					pre_x += s1.length * @font_width
					hl_x = s2.length * @font_width
					draw_rectangle_color(:hl_word, x+pre_x, y, hl_x, @font_height*@zoom)
					pre_x += hl_x
					stmp = stmp[s1.length+s2.length..-1]
				end
			end
			draw_string_color(color, x, y, str)
			x += str.length * @font_width
		}

		yoff = @font_height * @zoom
		b[:line_text_col].each { |list|
			list.each { |s, c| render[s, c] } if y >= -yoff
			x = (b.x - view_x + 1)*@zoom
			y += yoff
			break if y > w_h+2
		}

		if b == @caret_box and focus?
			cx = (b.x - view_x + 1 + @caret_x*@font_width)*@zoom
			cy = (b.y - view_y + 1 + @caret_y*@font_height)*@zoom
			draw_line_color(:caret, cx, cy, cx, cy+(@font_height-1)*@zoom)
		end
	end

	def gui_update
		@want_update_graph = true
		redraw
	end

	#
	# rebuild the code flow graph from @curcontext.roots
	# recalc the boxes w/h
	#
	def update_graph
		@want_update_graph = false

		ctx = @curcontext

		boxcnt = ctx.box.length
		arrcnt = ctx.box.inject(0) { |s, b| s + b.to.length + b.from.length }
		ctx.clear

		build_ctx(ctx)

		ctx.auto_arrange_boxes

		return if ctx != @curcontext

		if boxcnt != ctx.box.length or arrcnt != ctx.box.inject(0) { |s, b| s + b.to.length + b.from.length }
			zoom_all
		elsif @caret_box	# update @caret_box with a box at the same place
			bx = @caret_box.x + @caret_box.w/2
			by = @caret_box.y + @caret_box.h/2
			@caret_box = ctx.box.find { |cb| cb.x < bx and cb.x+cb.w > bx and cb.y < by and cb.y+cb.h > by }
		end
	end

	def load_dotfile(path)
		load_dot(File.read(path))
	end

	def load_dot(dota)
		@want_update_graph = false
		@curcontext.clear
		boxes = {}
		new_box = lambda { |text|
			b = @curcontext.new_box(text, :line_text_col => [[[text, :text]]])
			b.w = (text.length+1) * @font_width
			b.h = @font_height
			b
		}
		dota.scan(/^.*$/) { |l|
			a = l.strip.chomp(';').split(/->/).map { |s| s.strip.delete '"' }
			next if not id = a.shift
			b0 = boxes[id] ||= new_box[id]
			while id = a.shift
				b1 = boxes[id] ||= new_box[id]
				b0.to   |= [b1]
				b1.from |= [b0]
				b0 = b1
			end
		}
		redraw
	rescue Interrupt
		puts "dot_len #{boxes.length}"
	end

	# create the graph objects in ctx
	def build_ctx(ctx)
		# graph : block -> following blocks in same function
		block_rel = {}

		todo = ctx.root_addrs.dup
		done = [:default, Expression::Unknown]
		while a = todo.shift
			a = @dasm.normalize a
			next if done.include? a
			done << a
			next if not di = @dasm.di_at(a)
			if not di.block_head?
				block_rel[di.block.address] = [a]
				@dasm.split_block(a)
			end
			block_rel[a] = []
			di.block.each_to_samefunc(@dasm) { |t|
				t = @dasm.normalize t
				next if not @dasm.di_at(t)
				todo << t
				block_rel[a] << t
			}
			block_rel[a].uniq!
		end

		# populate boxes
		addr2box = {}
		todo = ctx.root_addrs.dup
		todo.delete_if { |t| not @dasm.di_at(t) }	# undefined func start
		done = []
		while a = todo.shift
			next if done.include? a
			done << a
			if not ctx.keep_split.to_a.include?(a) and from = block_rel.keys.find_all { |ba| block_rel[ba].include? a } and
					from.length == 1 and block_rel[from.first].length == 1 and
					addr2box[from.first] and lst = @dasm.decoded[from.first].block.list.last and
					lst.next_addr == a and (not lst.opcode.props[:saveip] or lst.block.to_subfuncret)
				box = addr2box[from.first]
			else
				box = ctx.new_box a, :addresses => [], :line_text_col => [], :line_address => []
			end
			@dasm.decoded[a].block.list.each { |di_|
				box[:addresses] << di_.address
				addr2box[di_.address] = box
			}
			todo.concat block_rel[a]
		end

		# link boxes
		ctx.box.each { |b|
			next if not di = @dasm.decoded[b[:addresses].last]
			a = di.block.address
			next if not block_rel[a]
			block_rel[a].each { |t|
				ctx.link_boxes(b.id, t)
				b.direct_to = t if t == di.next_addr
			}
		}

		# calc box dimensions/text
		ctx.box.each { |b|
			colstr = []
			curaddr = nil
			line = 0
			render = lambda { |str, col| colstr << [str, col] }
			nl = lambda {
				b[:line_address][line] = curaddr
				b[:line_text_col][line] = colstr
				colstr = []
				line += 1
			}
			b[:addresses].each { |addr|
				curaddr = addr
				if di = @dasm.di_at(curaddr)
					if di.block_head?
						# render dump_block_header, add a few colors
						b_header = '' ; @dasm.dump_block_header(di.block) { |l| b_header << l ; b_header << ?\n if b_header[-1] != ?\n }
						b_header.strip.each_line { |l| l.chomp!
							col = :comment
							col = :label if l[0, 2] != '//' and l[-1] == ?:
							render[l, col]
							nl[]
						}
					end
					render["#{Expression[curaddr]}   ", :address] if @show_addresses
					render[di.instruction.to_s.ljust(di.comment ? 24 : 0), :instruction]
					render[' ; ' + di.comment.join(' ')[0, 64], :comment] if di.comment
					nl[]
				else
					# TODO real data display (dwords, xrefs, strings..)
					if label = @dasm.get_label_at(curaddr)
						render[label + ' ', :label]
					end
					s = @dasm.get_section_at(curaddr)
					render['db '+((s and s[0].data.length > s[0].ptr) ? Expression[s[0].read(1)[0]].to_s : '?'), :text]
					nl[]
				end
			}
			b.w = b[:line_text_col].map { |strc| strc.map { |s, c| s }.join.length }.max.to_i * @font_width + 2
			b.w += 1 if b.w % 2 == 0	# ensure boxes have odd width -> vertical arrows are straight
			b.h = line * @font_height
		}
	end

	def keypress_ctrl(key)
		case key
		when ?F
			@parent_widget.inputbox('text to search in curview (regex)', :text => @hl_word) { |pat|
				re = /#{pat}/i
				list = [['addr', 'instr']]
				@curcontext.box.each { |b|
					b[:line_text_col].zip(b[:line_address]) { |l, a|
						str = l.map { |s, c| s }.join
						list << [Expression[a], str] if str =~ re
					}
				}
				@parent_widget.list_bghilight("search result for /#{pat}/i", list) { |i| @parent_widget.focus_addr i[0] }
			}
		when ?+; mouse_wheel_ctrl(:up, width/2, height/2)
		when ?-; mouse_wheel_ctrl(:down, width/2, height/2)
		else return false
		end
		true
	end

	def keypress(key)
		case key
		when :left
			if @caret_box
				if @caret_x > 0
					@caret_x -= 1
					update_caret
				elsif b = @curcontext.box.sort_by { |b_| -b_.x }.find { |b_| b_.x < @caret_box.x and
						b_.y < @caret_box.y+@caret_y*@font_height and
						b_.y+b_.h > @caret_box.y+(@caret_y+1)*@font_height }
					@caret_x = (b.w/@font_width).to_i
					@caret_y += ((@caret_box.y-b.y)/@font_height).to_i
					@caret_box = b
					update_caret
					redraw
				else
					@curcontext.view_x -= 20/@zoom
					redraw
				end
			else
				@curcontext.view_x -= 20/@zoom
				redraw
			end
		when :up
			if @caret_box
				if @caret_y > 0
					@caret_y -= 1
					update_caret
				elsif b = @curcontext.box.sort_by { |b_| -b_.y }.find { |b_| b_.y < @caret_box.y and
						b_.x < @caret_box.x+@caret_x*@font_width and
						b_.x+b_.w > @caret_box.x+(@caret_x+1)*@font_width }
					@caret_x += ((@caret_box.x-b.x)/@font_width).to_i
					@caret_y = b[:line_address].length-1
					@caret_box = b
					update_caret
					redraw
				else
					@curcontext.view_y -= 20/@zoom
					redraw
				end
			else
				@curcontext.view_y -= 20/@zoom
				redraw
			end
		when :right
			if @caret_box
				if @caret_x <= @caret_box[:line_text_col].map { |s| s.map { |ss, cc| ss }.join.length }.max
					@caret_x += 1
					update_caret
				elsif b = @curcontext.box.sort_by { |b_| b_.x }.find { |b_| b_.x > @caret_box.x and
						b_.y < @caret_box.y+@caret_y*@font_height and
						b_.y+b_.h > @caret_box.y+(@caret_y+1)*@font_height }
					@caret_x = 0
					@caret_y += ((@caret_box.y-b.y)/@font_height).to_i
					@caret_box = b
					update_caret
					redraw
				else
					@curcontext.view_x += 20/@zoom
					redraw
				end
			else
				@curcontext.view_x += 20/@zoom
				redraw
			end
		when :down
			if @caret_box
				if @caret_y < @caret_box[:line_address].length-1
					@caret_y += 1
					update_caret
				elsif b = @curcontext.box.sort_by { |b_| b_.y }.find { |b_| b_.y > @caret_box.y and
						b_.x < @caret_box.x+@caret_x*@font_width and
						b_.x+b_.w > @caret_box.x+(@caret_x+1)*@font_width }
					@caret_x += ((@caret_box.x-b.x)/@font_width).to_i
					@caret_y = 0
					@caret_box = b
					update_caret
					redraw
				else
					@curcontext.view_y += 20/@zoom
					redraw
				end
			else
				@curcontext.view_y += 20/@zoom
				redraw
			end
		when :pgup
			if @caret_box
				@caret_y = 0
				update_caret
			else
				@curcontext.view_y -= height/4/@zoom
				redraw
			end
		when :pgdown
			if @caret_box
				@caret_y = @caret_box[:line_address].length-1
				update_caret
			else
				@curcontext.view_y += height/4/@zoom
				redraw
			end
		when :home
			if @caret_box
				@caret_x = 0
				update_caret
			else
				@curcontext.view_x = @curcontext.box.map { |b_| b_.x }.min-10
				@curcontext.view_y = @curcontext.box.map { |b_| b_.y }.min-10
				redraw
			end
		when :end
			if @caret_box
				@caret_x = @caret_box[:line_text_col][@caret_y].to_a.map { |ss, cc| ss }.join.length
				update_caret
			else
				@curcontext.view_x = [@curcontext.box.map { |b_| b_.x+b_.w }.max-width/@zoom+10, @curcontext.box.map { |b_| b_.x }.min-10].max
				@curcontext.view_y = [@curcontext.box.map { |b_| b_.y+b_.h }.max-height/@zoom+10, @curcontext.box.map { |b_| b_.y }.min-10].max
				redraw
			end

		when :delete
			@selected_boxes.each { |b_|
				@curcontext.box.delete b_
				b_.from.each { |bb| bb.to.delete b_ }
				b_.to.each { |bb| bb.from.delete b_ }
			}
			redraw
		when :popupmenu
			if @caret_box
				cx = (@caret_box.x - view_x + 1 + @caret_x*@font_width)*@zoom
				cy = (@caret_box.y - view_y + 1 + @caret_y*@font_height)*@zoom
				rightclick(cx, cy)
			end

		when ?a
			t0 = Time.now
			puts 'autoarrange'
			@curcontext.auto_arrange_boxes
			redraw
			puts 'autoarrange done %.02f' % (Time.now - t0)
		when ?u
			gui_update

		when ?R
			load __FILE__
		when ?S	# reset
			@curcontext.auto_arrange_init(@selected_boxes.empty? ? @curcontext.box : @selected_boxes)
			puts 'reset', @curcontext.dump_layout, ''
			zoom_all
			redraw
		when ?T	# step auto_arrange
			@curcontext.auto_arrange_step
			puts @curcontext.dump_layout, ''
			zoom_all
			redraw
		when ?L	# post auto_arrange
			@curcontext.auto_arrange_post
			zoom_all
			redraw
		when ?V	# shrink
			@selected_boxes.each { |b_|
				dx = (b_.from + b_.to).map { |bb| bb.x+bb.w/2 - b_.x-b_.w/2 }
				dx = dx.inject(0) { |s, xx| s+xx }/dx.length
				b_.x += dx
			}
			redraw
		when ?I	# create arbitrary boxes/links
			if @selected_boxes.empty?
				@fakebox ||= 0
				b = @curcontext.new_box "id_#@fakebox",
					:addresses => [], :line_address => [],
					:line_text_col => [[["  blublu #@fakebox", :text]]]
				b.w = @font_width * 15
				b.h = @font_height * 2
				b.x = rand(200) - 100
				b.y = rand(200) - 100
				
				@fakebox += 1
			else
				b1, *bl = @selected_boxes
				bl = [b1] if bl.empty?	# loop
				bl.each { |b2|
					if b1.to.include? b2
						b1.to.delete b2
						b2.from.delete b1
					else
						b1.to << b2
						b2.from << b1
					end
				}
			end
			redraw

		when ?1	# (numeric) zoom to 1:1
			if @zoom == 1.0
				zoom_all
			else
				@curcontext.view_x += (width/2 / @zoom - width/2)
				@curcontext.view_y += (height/2 / @zoom - height/2)
				@zoom = 1.0
			end
			redraw
		when :insert		# split curbox at @caret_y
			if @caret_box and a = @caret_box[:line_address][@caret_y] and @dasm.decoded[a]
				@dasm.split_block(a)
				@curcontext.keep_split ||= []
				@curcontext.keep_split |= [a]
				gui_update
				focus_addr a
			end
		else return false
		end
		true
	end

	# find a suitable array of graph roots, walking up from a block (function start/entrypoint)
	def dasm_find_roots(addr)
		todo = [addr]
		done = []
		roots = []
		default_root = nil
		while a = todo.shift
			next if not di = @dasm.di_at(a)
			b = di.block
			a = b.address
			if done.include? a
				default_root ||= a
				next
			end
			done << a
			newf = []
			b.each_from_samefunc(@dasm) { |f| newf << f }
			if newf.empty?
				roots << b.address
			else
				todo.concat newf
			end
		end
		roots << default_root if roots.empty? and default_root

		roots
	end

	def set_cursor_pos(p)
		addr, x = p
		focus_addr(addr)
		@caret_x = x
		update_caret
	end

	def get_cursor_pos
		[current_address, @caret_x]
	end

	# focus on addr
	# addr may be a dasm label, dasm address, dasm address in string form (eg "0DEADBEEFh")
	# addr must point to a decodedinstruction
	# if the addr is not found in curcontext, the code flow is walked up until a function
	# start or an entrypoint is found, then the graph is created from there
	# will call gui_update then
	def focus_addr(addr, can_update_context=true)
		return if @parent_widget and not addr = @parent_widget.normalize(addr)
		return if not @dasm.di_at(addr)

		# move window / change curcontext
		if b = @curcontext.box.find { |b_| b_[:line_address].index(addr) }
			@caret_box, @caret_x, @caret_y = b, 0, b[:line_address].rindex(addr)
			@curcontext.view_x += (width/2 / @zoom - width/2)
			@curcontext.view_y += (height/2 / @zoom - height/2)
			@zoom = 1.0

			update_caret
		elsif can_update_context
			@curcontext = Graph.new 'testic'
			@curcontext.root_addrs = dasm_find_roots(addr)
			@want_focus_addr = addr
			gui_update
		else
			return
		end
		true
	end

	def focus_xy(x, y)
		if not view_x or view_x*@zoom + width*3/4 < x or view_x*@zoom > x
			@curcontext.view_x = (x - width/5)/@zoom
			redraw
		end
		if not view_y or view_y*@zoom + height*3/4 < y or view_y*@zoom > y
			@curcontext.view_y = (y - height/5)/@zoom
			redraw
		end
	end

	# hint that the caret moved
	# redraw, change the hilighted word
	def update_caret
		return if not b = @caret_box or not @caret_x or not l = @caret_box[:line_text_col][@caret_y]
		l = l.map { |s, c| s }.join
		@parent_widget.focus_changed_callback[] if @parent_widget and @parent_widget.focus_changed_callback and @oldcaret_y != @caret_y
		update_hl_word(l, @caret_x)
		focus_xy(b.x, b.y + @caret_y*@font_height)
		redraw
	end

	def current_address
		@caret_box ? @caret_box[:line_address][@caret_y] : @curcontext.root_addrs.first
	end
end
end
end
