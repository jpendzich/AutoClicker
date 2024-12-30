package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:sys/windows"
import "core:time"

foreign import user32 "system:User32.lib"

@(default_calling_convention = "system")
foreign user32 {
	RegisterHotKey :: proc(hWnd: windows.HWND, id: windows.INT, fsModifiers: windows.UINT, vk: windows.UINT) -> windows.BOOL ---
}

MOD_ALT :: 0x0001
MOD_CONTROL :: 0x0002
MOD_NONREPEAT :: 0x4000
MOD_SHIFT :: 0x0004
MOD_WIN :: 0x0008

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Need to provide the CPS number as the first argument")
		os.exit(1)
	}

	cps, ok := strconv.parse_f64(os.args[1])
	if (!ok) {
		fmt.println("Not a valid decimal number")
		os.exit(1)
	}

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

	durationBetweenClicks: f64 = 1000 / cps // in milliseconds
	lastClickTime := time.now()
	runningAutoClicker := false

	for {
		runningAutoClicker = isHotkeyPressed()
		for runningAutoClicker {
			runningAutoClicker = runningAutoClicker && !isHotkeyPressed()
			if (time.duration_milliseconds(time.diff(lastClickTime, time.now())) >
				   durationBetweenClicks) {
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
