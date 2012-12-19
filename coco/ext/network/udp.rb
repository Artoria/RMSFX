=begin
# 
# Created by Hana Seiran 
#
# Documentation by Hana Seiran
#

Lisense:

Copyright (c) 2012, Seiran
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
   This product includes software developed by Seiran.

THIS SOFTWARE IS PROVIDED BY Seiran ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Seiran BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end

require 'Coco/ext/network/winsock2'
class CocoSimple::UDPSocket 
        WINSOCK = CocoSimple::DLL.new('ws2_32')
        def self.init
                wsadata = "\0"*128
                WINSOCK.WSAStartup(0x0202, wsadata)
        end
        def self.fini
                WINSOCK.WSACleanup
        end

        def initialize
                @socket = WINSOCK.socket(CocoSimple::WinSock2Constants::AF_INET, CocoSimple::WinSock2Constants::SOCK_DGRAM, CocoSimple::WinSock2Constants::IPPROTO_IP)
        end

        SOCK_ADDR = CocoSimple::Struct.new do
                int16 sin_family;
                uint16  sin_port;
                int32  addr;
                int32  _, _;
        end

        def udpaddr arr, port
                x = SOCK_ADDR.new
                x.sin_family = CocoSimple::WinSock2Constants::AF_INET
                x.sin_port   = WINSOCK.ntohs(port)
                x.addr       = arr.pack('C*').unpack('L').first
                x
        end
        
        def bind addr, port
                x = udpaddr(addr,port)
                raise "bind #{addr}:#{port}" if WINSOCK.bind(@socket, x.__data__, x.__data__.length) != 0
                        
        end
        def recv  timeout = 10000, maxlen = 1024
                buf = "\0"*maxlen
                ar = "\0"*64
                len = [ar.length].pack('L')
                outlen = 0
                t = Time.now
                ret = nil
                timeout.times{
                        outlen = WINSOCK.recvfrom @socket, buf, maxlen, 0, ar, len
                        if outlen > 0
                                ret = [buf[0, outlen], SOCK_ADDR.new(ar)]
                                break
                        end
                }
                ret
        end
        def send buf, ar
                WINSOCK.sendto @socket, buf, buf.length, 0, ar, ar.__data__.length
        end
end


