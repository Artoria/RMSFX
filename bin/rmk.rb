class RMK
  attr_accessor :config, :path
  Tasks = Struct.new(:name, :deps, :action, :done)
  def initialize
    @tasks = {}
    @taskdone = {}
    self.config = {}
  end

  def [](*a) config.[](*a) end
  def []=(*a) config.[]=(*a) end

  def task(name, deps = [], &b)
    name = name.to_sym
    @tasks[name] = Tasks.new(name, deps, b, false)
  end

  def run(name, *a, &b)
    name = name.to_sym
    t = @tasks[name]
    u = @taskdone[[name, *a]]
    unless u
     begin
        t.deps.each{|x| run(x)}
        puts "Running \"#{([name]+a).join(':')}\" (#{name}) task"
        t.action.call(*a, &b)
        @taskdone[[name, *a]] = true
      rescue Exception
        puts "\ttask aborted - #{$!.to_s}"
        puts $!.backtrace.map{|x| "\t\t#{x}"}
      end
    end
  end

  def start
    ARGV.each{|x|
      run *x.split(":", 2)
    }
  end

  def start_opt
    x   = ARGV.shift
    opt = ARGV.inject({}){|a, b|
       r,s = b.split(":", 2)
       a[r] = s
       a
    }
    run x, opt
  end

  def start_opt_x
    x   = ARGV.shift
    opt = ARGV.inject({}){|a, b|
       r,s = b.split(":")
       a[r] = s
       a
    }
    run x, opt
  end

  def runargs
    run *ARGV
  end

  def find_rmk(name, a = [Dir.getwd, resolve("tasks")])
    a.map{|x| x = x.tr('\\', '/'); Dir.glob("#{x}/#{name}").to_a + Dir.glob("#{x}/#{name}.rmk").to_a}.flatten.compact
  end

  def resolve(a = "")
    "C:/RMSFX/rmk/#{a}"
  end

  def resolve_path(a = "")
    @path + "/#{a}"
  end

  def ft_cmp(a, b, op = :<=>)
    a.map{|x| File.mtime(x).to_i rescue 1e100 }.max{|x, y| x.send(op, y)}.send(op, b.map{|x| File.mtime(x).to_i rescue -1e100}.min{|x, y| x.send(op, y)})
  end

end

def rmk
  $rmk ||= RMK.new
end

rmk.find_rmk(ARGV.shift).each{|x|
  puts "RMK #{x}"
  rmk.path = File.dirname(x)
  load x
}

puts "Done."