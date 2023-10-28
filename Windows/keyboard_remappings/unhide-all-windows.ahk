#Requires AutoHotkey v2.0

DetectHiddenWindows True

; Unhides all windows (Idk where they go so this is all I could think of to find them).
; Open another instance of the app you're trying to unhide and press Alt+S to unhide all
; instances of it.
; Only meant to be used once and then de-activated, not running all the time.
;
; See:
;   - https://www.autohotkey.com/boards/viewtopic.php?t=91930
;   - https://www.autohotkey.com/boards/viewtopic.php?style=7&t=99897
;   - https://www.autohotkey.com/board/topic/15652-list-all-open-windows/
!s:: {
    local windowId := WinActive("A")
    local windowClass := WinGetClass("A")
    local activeProcessName := WinGetProcessName("A")
    local windowList := WinGetList("ahk_exe" activeProcessName)

    for i,v in windowList
        WinShow(v)
}
