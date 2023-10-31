#Requires AutoHotkey v2.0


; Alt+` to switch between windows of the same app, but without
; putting previously-selected windows at the bottom of the z-index.
; This behaves like Ubuntu where pressing Alt+` once will swap between
; the last two windows focused by the user.
;
; We could bind multiple key-combos, e.g.
; !`::
; !+`:: { <logic> }
; but that would cause the `swapWindowsOfSameApp()` function to be called once with each key-combo if the
; previous call didn't end.
; i.e. Pressing "Alt+`, Alt+`, Alt+Shift+`, Alt+`" would result in `swapWindowsOfSameApp()` being called twice
; (once for Alt+` and a second time for Alt+Shift+`).
; Thus, to allow both of them to work in harmony, allow all key modifiers (Ctrl, Caps-lock, Super, etc.) to
; be captured by the same block via the `*` prefix, and then filter out the cases where relevant modifiers (namely
; Ctrl and Super) are being pressed to simulate only allowing Alt+` and Alt+Shift+`.
; See:
;   - https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols
;   - https://www.autohotkey.com/boards/viewtopic.php?t=81355
*!`:: {
    ; Don't run if another modifier besides Alt and Shift is used.
    ; There is no single `Win` key, so specify both Left/Right Win buttons (https://www.autohotkey.com/docs/v1/KeyList.htm#modifier).
    if (GetKeyState("Ctrl") || GetKeyState("LWin") || GetKeyState("RWin")) {
        return
    }

    Send '{Blind}{Alt down}'  ; "Mask" the standard Alt-down event.
    swapWindowsOfSameApp()
}

; Original
; !+`:: {
;     windowId := WinActive("A")
;     windowClass := WinGetClass("A")
;     activeProcessName := WinGetProcessName("A")
;     ; We have to be extra careful about explorer.exe since that process is responsible for more than file explorer
;     if (activeProcessName = "explorer.exe")
;         windowList := WinGetList("ahk_exe" activeProcessName " ahk_class" windowClass)
;     else
;         windowList := WinGetList("ahk_exe" activeProcessName)
;
;     ; Take window from bottom of list
;     lastWindowIndex := windowList.Length
;     windowToFocusId := windowList[lastWindowIndex]
;
;     ; Activate the next window and send it to the top.
;     WinMoveTop("ahk_id" windowToFocusId)
;     WinActivate("ahk_id" windowToFocusId)
; }

; Alternative: Moves previous window from Alt+` to bottom of z-index stack
; Would need to add !+` (Alt+Shift+`) as well
; !`:: {
;     OldClass := WinGetClass("A")
;     ActiveProcessName := WinGetProcessName("A")
;     WinClassCount := WinGetCount("ahk_exe" ActiveProcessName)
;     IF WinClassCount = 1
;         Return
;     loop 2 {
;         WinMoveBottom("A")
;         WinActivate("ahk_exe" ActiveProcessName)
;         NewClass := WinGetClass("A")
;         if (OldClass != "CabinetWClass" or NewClass = "CabinetWClass")
;             break
;     }
; }



; See: https://superuser.com/questions/1604626/easy-way-to-switch-between-two-windows-of-the-same-app-in-windows-10/1783158#1783158

; Other ideas:
;   - Alt+Tab through windows only on that monitor: https://www.autohotkey.com/boards/viewtopic.php?t=54972


arrayToString(strArray) {
    ; See: https://stackoverflow.com/questions/46002967/how-do-i-print-an-array-in-autohotkey
    local s := ""

    for i in strArray
        s .= ", " . i

    return substr(s, 3)
}

arrayReverse(arr) {
    ; See:
    ;   - https://www.autohotkey.com/boards/viewtopic.php?t=39399
    ;   - https://www.autohotkey.com/boards/viewtopic.php?t=31888
    local len := arr.Length
    local arrTmp := arr.clone()  ; Temp array so we can use Array.pop() method
    local arrRev := []

    local i,v
    for i,v in arr {
        ; arrRev[len - i + 1] := arrTmp.pop()  ; AutoHotKey Arrays start at index 1 instead of 0
        arrRev.Push(arrTmp.pop())
    }

    return arrRev
}

resetWindowZOrder(windowList, windowToIgnoreId := 0) {
    ; Iterate through the original window stack list to prevent our `WinActivate()` call above from modifying
    ; the resulting stack list beyond only moving the selected window to the top.
    ; Otherwise, the stack will be overwritten with the order we cycled through when choosing which window
    ; we wanted even though those windows weren't chosen.

    local i,v
    for i,v in arrayReverse(windowList) {
        if (v != windowToIgnoreId) {
            WinMoveTop("ahk_id" v)
        }
    }
}


swapWindowsOfSameApp(swapDelta := 1) {
    local windowId := WinActive("A")
    local windowClass := WinGetClass("A")
    local activeProcessName := WinGetProcessName("A")

    local windowList := []

    ; We have to be extra careful about explorer.exe since that process is responsible for more than file explorer
    if (activeProcessName = "explorer.exe")
        windowList := WinGetList("ahk_exe" activeProcessName " ahk_class" windowClass)
    else
        windowList := WinGetList("ahk_exe" activeProcessName)

    ; Copy original window list to allow us to activate the potential window as a preview
    ; when cycling through all windows while also being able to return the original z-index
    ; stack list back to how it was and go both forward/backward depending on pressing Shift
    local i, v, windowListOrig := []
    for i,v in windowList
        windowListOrig.Push(v)

    ; Only for debugging purposes
    log := []
    for i,v in windowList
        log.Push(i "-" v)

    local firstWindowIndex := 1
    local lastWindowIndex := windowList.Length
    local windowToFocusIndex := 1

    ; Not needed, was used to force one Alt+` combo to go to the next window in case
    ; it wasn't captured by the while-loop
    ; if (windowToFocusIndex > windowList.Length) {
    ;     windowToFocusIndex := 1
    ; } else {
    ;     windowToFocusIndex := windowToFocusIndex + 1
    ; }

    ; MsgBox("Start: " arrayToString(log) "=" windowToFocusIndex, "Window List")

    local windowToFocusId := windowList[windowToFocusIndex]

    ; while KeyWait("Alt") != 0 { ; Doesn't work since `KeyWait()` blocks execution of other lines
    while GetKeyState("Alt") {
        if GetKeyState("Escape", "P") {
            resetWindowZOrder(windowListOrig)

            return
        }


        ; KeyWait("``", "D")  ; This might work, it wasn't tested in conjunction with the `Sleep` call below
        ; MsgBox("Backtick pressed " windowToFocusIndex, "Info when Alt+Backtick was pressed")

        if GetKeyState("``", "P") {
            local debugIndex := windowToFocusIndex

            ; Handle Alt+` vs Alt+Shift+` here so that the `windowToFocusIndex` is maintained when
            ; using both within one execution sequence (must be paired with *!`:: key remapping scheme)
            if GetKeyState("Shift", "P") {
                windowToFocusIndex := windowToFocusIndex - swapDelta
            } else {
                windowToFocusIndex := windowToFocusIndex + swapDelta
            }

            if (windowToFocusIndex > windowList.Length) {
                windowToFocusIndex := 1
            } else if (windowToFocusIndex < 1) {
                windowToFocusIndex := windowList.Length
            }

            ; MsgBox("Backtick pressed: Orig=" debugIndex " New=" windowToFocusIndex " swapDelta=" swapDelta, "More Info")

            windowToFocusId := windowListOrig[windowToFocusIndex]

            ; Show preview of window. This in conjunction with the `windowListOrig` iteration below is a
            ; hacky way to maintain the original window-list order.
            ; See: https://www.autohotkey.com/board/topic/145368-is-there-is-a-way-to-show-live-preview-of-a-window/
            WinActivate("ahk_id" windowToFocusId)
            ; WinMoveTop("ahk_id" windowToFocusId)  ; Causes multiple activate/move-to-top events to fire at once :(
            ; Another attempt, but only works on hidden windows: WinShow(windowListOrig[windowToFocusIndex])
        }

        Sleep 100  ; Necessary to prevent the loop from being marked "idle" and the function exiting prematurely
    }

    ; Ignore chosen window since it will be moved to the top of the stack below
    resetWindowZOrder(windowListOrig, windowToFocusId)

    ; MsgBox(arrayToString(log) "=" windowToFocusIndex, "Final window-to-focus index")

    WinActivate("ahk_id" windowToFocusId)  ; Activate the next window (should also bring it to top of stack)
    WinMoveTop("ahk_id" windowToFocusId)  ; Send window to the top of the stack (doesn't activate it)

    ; Wait until Alt is released before ending execution of this function
    KeyWait("Alt")
}
