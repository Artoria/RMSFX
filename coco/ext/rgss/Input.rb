module Input
        USER32 = CocoSimple::DLL.new('user32')
        KERNEL32 = CocoSimple::DLL.new('kernel32')        
        IMM32 = CocoSimple::DLL.new('imm32')        
        MSG = CocoSimple::Struct.new {
                uint32 hwnd;
                uint32 message;
                uint16 wParam;
                uint32 lParam;
                uint16 time;
                uint32 x;
                uint32 y;
        }
        KEYBOARD = Array.new(65536).map{nil}
        HookKeyboard = CocoSimple::Callback.new{|code, wp, lp|
                Input::KEYBOARD[wp] = lp;
                USER32.CallNextHookEx 0, code, wp, lp
        }
        TEXT = ""
        MSGLOCK = "\0"* 1024 
        KERNEL32.InitializeCriticalSection MSGLOCK
        HookMsg = CocoSimple::Callback.new{|code, wp, lp|
                begin
                        msg = MSG.new
                        KERNEL32.RtlMoveMemory msg, lp, MSG.sizeof
                        if msg.message == 0x50              #Input Method Change
                                p "IME enabled"
                                next USER32.DefWindowProcA msg.hwnd, msg.message, msg.wParam, msg.lParam
                        end
                        if msg.message == 0x10F && wp == 1 #Input Composition String (On Any Input Method Event)
                                hwnd = USER32.GetFocus
                                himc = IMM32.ImmGetContext(hwnd)
                                size = IMM32.ImmGetCompositionString(himc,  0x800, 0, 0)
                                if size != 0
                                        buf = "\0"*size
                                        IMM32.ImmGetCompositionString(himc,  0x800, buf, size)
                                        IMM32.ImmReleaseContext(himc)
                                        KERNEL32.EnterCriticalSection MSGLOCK
                                           TEXT << buf
                                        KERNEL32.LeaveCriticalSection MSGLOCK
                                end
                                next 0
                        end
                        if msg.message == 0x102
                                KEYBOARD[msg.wParam] = 0xFFFFFFFF
                        end

                        USER32.CallNextHookEx 0, code, wp, lp
                rescue Object => ex
                        p ex 
                        p ex.backtrace
                        USER32.CallNextHookEx 0, code, wp, lp
                end                        
        }

        #USER32.SetWindowsHookEx 2, HookKeyboard, 0, KERNEL32.GetCurrentThreadId
        HOOK = USER32.SetWindowsHookEx  3, HookMsg, 0, KERNEL32.GetCurrentThreadId
        class << self
                alias oldupdate update
        end
        @@t = Time.now
        INTERVAL = 0.5
end



