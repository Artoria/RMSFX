
load_data('C:/RMSFX/Data/RMXP.rxdata').each{|x|
	a,b,c = x
	c=Zlib::Inflate.inflate c
  	eval c, TOPLEVEL_BINDING, b, 1
}
