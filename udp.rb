module WinSock2Constants
      _WINSOCK=2
    _GNU_H_WINDOWS3=2
    FD_SETSIZE=64
    SD_RECEIVE=0x00
    SD_SEND=0x01
    SD_BOTH=0x02
    IOCPARM_MASK=0x7
    IOC_VOID=0x20000000
    IOC_OUT=0x40000000
    IOC_IN=0x80000000
    IPPROTO_IP=0
    IPPROTO_ICMP=1
    IPPROTO_IGMP=2
    IPPROTO_GGP=3
    IPPROTO_TCP=6
    IPPROTO_PUP=12
    IPPROTO_UDP=17
    IPPROTO_IDP=22
    IPPROTO_ND=77
    IPPROTO_RAW=255
    IPPROTO_MAX=256
    IPPROTO_HOPOPTS=0
    IPPROTO_IPV6=41
    IPPROTO_ROUTING=43
    IPPROTO_FRAGMENT=44
    IPPROTO_ESP=50
    IPPROTO_AH=51
    IPPROTO_ICMPV6=58
    IPPROTO_NONE=59
    IPPROTO_DSTOPTS=60
    IPPORT_ECHO=7
    IPPORT_DISCARD=9
    IPPORT_SYSTAT=11
    IPPORT_DAYTIME=13
    IPPORT_NETSTAT=15
    IPPORT_FTP=21
    IPPORT_TELNET=23
    IPPORT_SMTP=25
    IPPORT_TIMESERVER=37
    IPPORT_NAMESERVER=42
    IPPORT_WHOIS=43
    IPPORT_MTP=57
    IPPORT_TFTP=69
    IPPORT_RJE=77
    IPPORT_FINGER=79
    IPPORT_TTYLINK=87
    IPPORT_SUPDUP=95
    IPPORT_EXECSERVER=512
    IPPORT_LOGINSERVER=513
    IPPORT_CMDSERVER=514
    IPPORT_EFSSERVER=520
    IPPORT_BIFFUDP=512
    IPPORT_WHOSERVER=513
    IPPORT_ROUTESERVER=520
    IPPORT_RESERVED=1024
    IMPLINK_IP=155
    IMPLINK_LOWEXPER=156
    IMPLINK_HIGHEXPER=158
    IN_CLASSA_NET=0
    IN_CLASSA_NSHIFT=24
    IN_CLASSA_HOST=0x00
    IN_CLASSA_MAX=128
    IN_CLASSB_NET=0
    IN_CLASSB_NSHIFT=16
    IN_CLASSB_HOST=0x0000
    IN_CLASSB_MAX=65536
    IN_CLASSC_NET=0
    IN_CLASSC_NSHIFT=8
    IN_CLASSC_HOST=0
    INADDR_LOOPBACK=0x7
    INADDR_NONE=0
    WSADESCRIPTION_LEN=256
    WSASYS_STATUS_LEN=128
    IP_OPTIONS=1
    SO_DEBUG=1
    SO_ACCEPTCONN=2
    SO_REUSEADDR=4
    SO_KEEPALIVE=8
    SO_DONTROUTE=16
    SO_BROADCAST=32
    SO_USELOOPBACK=64
    SO_LINGER=128
    SO_OOBINLINE=256
    SO_SNDBUF=0x1001
    SO_RCVBUF=0x1002
    SO_SNDLOWAT=0x1003
    SO_RCVLOWAT=0x1004
    SO_SNDTIMEO=0x1005
    SO_RCVTIMEO=0x1006
    SO_ERROR=0x1007
    SO_TYPE=0x1008
    SOCK_STREAM=1
    SOCK_DGRAM=2
    SOCK_RAW=3
    SOCK_RDM=4
    SOCK_SEQPACKET=5
    TCP_NODELAY=0x0001
    AF_UNSPEC=0
    AF_UNIX=1
    AF_INET=2
    AF_IMPLINK=3
    AF_PUP=4
    AF_CHAOS=5
    AF_IPX=6
    AF_NS=6
    AF_ISO=7
    AF_ECMA=8
    AF_DATAKIT=9
    AF_CCITT=10
    AF_SNA=11
    AF_DECnet=12
    AF_DLI=13
    AF_LAT=14
    AF_HYLINK=15
    AF_APPLETALK=16
    AF_NETBIOS=17
    AF_VOICEVIEW=18
    AF_FIREFOX=19
    AF_UNKNOWN1=20
    AF_BAN=21
    AF_ATM=22
    AF_INET6=23
    AF_CLUSTER=24
    AF_12844=25
    AF_IRDA=26
    AF_NETDES=28
    AF_MAX=29
    PF_UNKNOWN=1
    PF_INET=6
    SOL_SOCKET=0
    SOMAXCONN=0x7
    MSG_OOB=1
    MSG_PEEK=2
    MSG_DONTROUTE=4
    MSG_MAXIOVLEN=16
    MSG_PARTIAL=0x8000
    MAXGETHOSTSTRUCT=1024
    FD_READ_BIT=0
    FD_WRITE_BIT=1
    FD_OOB_BIT=2
    FD_ACCEPT_BIT=3
    FD_CONNECT_BIT=4
    FD_CLOSE_BIT=5
    FD_QOS_BIT=6
    FD_GROUP_QOS_BIT=7
    FD_ROUTING_INTERFACE_CHANGE_BIT=8
    FD_ADDRESS_LIST_CHANGE_BIT=9
    FD_MAX_EVENTS=10
    WSABASEERR=10000
    IN_CLASSD_NET=0
    IN_CLASSD_NSHIFT=28
    IN_CLASSD_HOST=0x0
    SO_GROUP_ID=0x2001
    SO_GROUP_PRIORITY=0x2002
    SO_MAX_MSG_SIZE=0x2003
    SO_PROTOCOL_INFOA=0x2004
    SO_PROTOCOL_INFOW=0x2005
    PVD_CONFIG=0x3001
    MSG_INTERRUPT=0x10
    MSG_MAXIOVLEN=16
    WSA_WAIT_EVENT_=0
    CF_ACCEPT=0x0000
    CF_REJECT=0x0001
    CF_DEFER=0x0002
    SD_RECEIVE=0x00
    SD_SEND=0x01
    SD_BOTH=0x02
    SG_UNCONSTRAINED_GROUP=0x01
    SG_CONSTRAINED_GROUP=0x02
    MAX_PROTOCOL_CHAIN=7
    BASE_PROTOCOL=1
    LAYERED_PROTOCOL=0
    LUP_DEEP=0x0001
    LUP_CONTAINERS=0x0002
    LUP_NOCONTAINERS=0x0004
    LUP_NEAREST=0x0008
    LUP_RETURN_NAME=0x0010
    LUP_RETURN_TYPE=0x0020
    LUP_RETURN_VERSION=0x0040
    LUP_RETURN_COMMENT=0x0080
    LUP_RETURN_ADDR=0x0100
    LUP_RETURN_BLOB=0x0200
    LUP_RETURN_ALIASES=0x0400
    LUP_RETURN_QUERY_STRING=0x0800
    LUP_RETURN_ALL=0x0
    LUP_RES_SERVICE=0x8000
    LUP_FLUSHCACHE=0x1000
    LUP_FLUSHPREVIOUS=0x2000
    WSAPROTOCOL_LEN=255
    PFL_MULTIPLE_PROTO_ENTRIES=0x00000001
    PFL_RECOMMENDED_PROTO_ENTRY=0x00000002
    PFL_HIDDEN=0x00000004
    PFL_MATCHES_PROTOCOL_ZERO=0x00000008
    XP1_CONNECTIONLESS=0x00000001
    XP1_GUARANTEED_DELIVERY=0x00000002
    XP1_GUARANTEED_ORDER=0x00000004
    XP1_MESSAGE_ORIENTED=0x00000008
    XP1_PSEUDO_STREAM=0x00000010
    XP1_GRACEFUL_CLOSE=0x00000020
    XP1_EXPEDITED_DATA=0x00000040
    XP1_CONNECT_DATA=0x00000080
    XP1_DISCONNECT_DATA=0x00000100
    XP1_SUPPORT_BROADCAST=0x00000200
    XP1_SUPPORT_MULTIPOINT=0x00000400
    XP1_MULTIPOINT_CONTROL_PLANE=0x00000800
    XP1_MULTIPOINT_DATA_PLANE=0x00001000
    XP1_QOS_SUPPORTED=0x00002000
    XP1_INTERRUPT=0x00004000
    XP1_UNI_SEND=0x00008000
    XP1_UNI_RECV=0x00010000
    XP1_IFS_HANDLES=0x00020000
    XP1_PARTIAL_MESSAGE=0x00040000
    BIGENDIAN=0x0000
    LITTLEENDIAN=0x0001
    SECURITY_PROTOCOL_NONE=0x0000
    JL_SENDER_ONLY=0x01
    JL_RECEIVER_ONLY=0x02
    JL_BOTH=0x04
    WSA_FLAG_OVERLAPPED=0x01
    WSA_FLAG_MULTIPOINT_C_ROOT=0x02
    WSA_FLAG_MULTIPOINT_C_LEAF=0x04
    WSA_FLAG_MULTIPOINT_D_ROOT=0x08
    WSA_FLAG_MULTIPOINT_D_LEAF=0x10
    IOC_UNIX=0x00000000
    IOC_WS2=0x08000000
    IOC_PROTOCOL=0x10000000
    IOC_VENDOR=0x18000000
    TH_NETDEV=0x00000001
    TH_TAPI=0x00000002
end

require 'dynamic'
Winsock = Roost::Dynamic::Dyn.new('ws2_32.dll').instance_eval{

    def init
      wsadata = "\0"*1024
      WSAStartup(0x0202, wsadata)
      @init ||= 0
      @init += 1
    end
    
    def udpsocket
      self.socket(WinSock2Constants::AF_INET, WinSock2Constants::SOCK_DGRAM, WinSock2Constants::IPPROTO_IP)
    end
    #api.closesocket
    def make_sockaddr_in(sin_family, sin_port, sin_addr, sin_zero = "\0"*8)
      [sin_family, sin_port].pack('sS')+ sin_addr + sin_zero
    end
    
    def make_sin_addr(a,b,c,d)
      [a,b,c,d].pack('CCCC')
    end
    
    def udpbind(a,b)
      bind(a,b,b.length)
    end
    
    def udprecv(so, maxlen = 1024, addr_in = "\0"* 64)
      buf = "\0"*maxlen
      ar  = addr_in
      len = [ar.length].pack('L')
      outlen = 0
      loop do
        outlen = recvfrom so, buf, maxlen, 0, ar, len
        break if outlen > 0
      end
      [buf[0, outlen], ar]
    end

    def udprecvraw(so, maxlen = 1024, addr_in = "\0"* 64)
      buf = "\0"*maxlen
      ar  = addr_in
      len = [ar.length].pack('L')
      outlen = recvfrom so, buf, maxlen, 0, ar, len
      [buf[0, outlen], ar, outlen]
    end

    
    def udpsend(so, buf, addr_in)
      sendto so, buf, buf.length, 0, addr_in, addr_in.length
    end
    
    def fini
      WSACleanup()
    end
    
    def udpaddr a,port
      make_sockaddr_in WinSock2Constants::AF_INET, 
                       Winsock.htons(port), 
                       Winsock.make_sin_addr(*a)
                      
    end
    self
}


class UDP
    attr_accessor :in_addr, :buf, :err
    class EndPoint
      attr_accessor :addr, :port 
      def initialize(addr, port = nil)
       if port                       
        @addr = Winsock.udpaddr(addr, port)
       else
        @addr = addr
       end
      end
    end

    def bind(endpoint)
      Winsock.udpbind @socket, endpoint.addr
    end

    def create_pipes
        @pr, @pw = IO.pipe
    end

    def initialize
      Winsock.init
      create_pipes
      @socket = Winsock.udpsocket
      @fdset = [1, @socket].pack("LL") + "\0\0\0\0"*63
    end

    def send(buf, addr = nil)
      addr ||= @in_addr
      Winsock.udpsend @socket, buf, addr.addr
    end

    def pull(maxlen = 1024)
      ret = Winsock.udprecvraw @socket, maxlen
      @in_addr = EndPoint.new([0,0,0,0],0)
      @in_addr.addr = ret[1]
      @buf = ret[0]
    end

    def receive(maxlen = 1024, mius_timeout = 1000000)
      @timeout = [mius_timeout / 1000000, mius_timeout % 1000000].pack("LL")
      @ret = Winsock.select 0, @fdset, 0, 0, @timeout
      if @ret == -1
         @err = Winsock.WSAGetLastError
         return ""
      elsif @ret != 0
        pull maxlen
      else
         ""
      end
    end
end
