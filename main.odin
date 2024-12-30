package main

import "core:sys/windows"
import "core:time"

foreign import user32 "system:User32.lib"

@(default_calling_convention="system")
foreign user32 {
	RegisterHotKey :: proc(hWnd: windows.HWND, id: windows.INT, fsModifiers: windows.UINT, vk: windows.UINT) -> windows.BOOL ---
}

MOD_ALT :: 0x0001
MOD_CONTROL :: 0x0002
MOD_NONREPEAT :: 0x4000
MOD_SHIFT :: 0x0004
MOD_WIN :: 0x0008

main :: proc() {
	leftdown := windows.INPUT {
		type = .MOUSE,
		mi = windows.MOUSEINPUT {
			dx = 0,
			dy = 0,
			mouseData = 0,
			dwFlags = windows.MOUSEEVENTF_LEFTDOWN,
			time = 0,
		},
	}
	leftup := windows.INPUT {
		type = .MOUSE,
		mi = windows.MOUSEINPUT {
			dx = 0,
			dy = 0,
			mouseData = 0,
			dwFlags = windows.MOUSEEVENTF_LEFTUP,
			time = 0,
		},
	}

	// 0x41 == 'A'
  	RegisterHotKey(nil, 1, MOD_ALT | MOD_NONREPEAT, 0x41)

	runningAutoClicker := false
	durationBetweenClicks: f64 = 100 // in milliseconds
	lastClickTime := time.now()

  	for {
  		runningAutoClicker = isHotkeyPressed()
		for runningAutoClicker {
			runningAutoClicker = runningAutoClicker && !isHotkeyPressed()
			if (time.duration_milliseconds(time.diff(lastClickTime, time.now())) > durationBetweenClicks) {
				lastClickTime = time.now()
				windows.SendInput(1, &leftdown, size_of(leftdown))
				windows.SendInput(1, &leftup, size_of(leftup))
			}
		}
	}
}

isHotkeyPressed :: proc() -> bool {
	msg: windows.MSG
	if (windows.PeekMessageW(&msg, nil, 0, 0, windows.PM_REMOVE)) {
		if (msg.message == windows.WM_HOTKEY) {
			return true
		}
		return false
	}
	return false
}
