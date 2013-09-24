require 's20'
require 'ver'
require 'stub'
module Which
        module_function        
        def initRTP
                SimplePipe::run("REG EXPORT HKLM\\SOFTWARE\\Enterbrain rtp.ini")
                @@rtpini = ini_reader(Seiran20.to_mb(File.read("rtp.ini")))
                File.unlink("rtp.ini")
                case
                        when VER::XP
                             @@rtpstr = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Enterbrain\\RGSS\\RTP"
                        when VER::VX
                             @@rtpstr = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Enterbrain\\RGSS2\\RTP"
                        when VER::VA
                             @@rtpstr = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Enterbrain\\RGSS3\\RTP"
                end
                @@exe = which("$exe")
                @@exename = @@exe.sub(/\.exe$/i){}
                @@ininame = @@exename + ".ini"
                @@gameini = ini_reader(File.read @@ininame)
            
                @@rtpslot =[@@gameini["Game"]["RTP"],@@gameini["Game"]["RTP1"],@@gameini["Game"]["RT2"],@@gameini["Game"]["RT3"]].compact
                @@rtppath = [which("$dir")].concat @@rtpslot.map{|x| @@rtpini[@@rtpstr]['"' << x << '"']}.compact.map{|x| x.gsub(/^\"|\"$/){}.gsub(/\\\\/){"\\"}}
        end

        def ini_reader(ini)
            @value = {}
            x = ini.split(/[\r\n]+/).each{|x|
                   if /\[(.+)\]/ =~ x
                          @inikey = $1
                          @value[@inikey] ||= {}
                   elsif /(.+)=(.+)/=~x
                          @value[@inikey][$1] = $2
                   end
            }
            @value
        end
        def which(path)
                x,y = path.split("://")
                if y == nil
                        default(x)
                else
                        send x, y
                end
        end
        def default(name)
                case name
                when "$exe"
                        Seiran20.api("Kernel32", "GetModuleFileNameW").call 0, buf="\0"*1024, 1024
                        Seiran20.to_mb(buf).sub(/\0+$/){}
                when "$dir"
                        Seiran20.api("Kernel32", "GetModuleFileNameW").call 0, buf="\0"*1024, 1024
                        Seiran20.api("shlwapi", "PathRemoveFileSpecW").call buf
                        Seiran20.to_mb(buf).sub(/\0+$/){}
                else
                        nil
                end
        end
        def dll(path)
                path = path.tr("/", "\\")
                (ENV["path"].split(";")+["."]).reverse.each{|x|
                        if FileTest.file?(name = x + "\\" + path)
                                return name
                        end
                }
                nil
        end
        def rtp(path)
                path = path.tr("/", "\\")
                @@rtppath.each{|x|
                        if FileTest.exist?(name = x + "\\" + path)
                                return name
                        end
                        Dir.glob(name.tr("\\", "/") + ".*").each{|y|
                                return y.tr("/", "\\")
                        }
                }
                nil
        end
        def font(name)
                ans = []
                @@font.values[0].each{|k, v|
                    ans << v if k[name]
                }
                ans
        end
        def initFont
                  SimplePipe::run("REG EXPORT \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\" font.ini")                
                  @@font = ini_reader(Seiran20.to_mb(File.read("font.ini")))
                  File.unlink("font.ini")
        end
        initRTP
        initFont
end

class Object
        include Which
end

