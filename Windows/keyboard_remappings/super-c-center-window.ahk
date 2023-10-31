; #Requires AutoHotkey v2.0


global debug := false


#c:: {
    ; See:
    ;   - StackOverflow: https://superuser.com/questions/403187/need-autohotkey-to-center-active-window
    global debug

    local windowId := WinActive("A")

    local windowX, windowY, windowWidth, windowHeight
    WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, windowId)

    local monitorLeft, monitorRight, monitorTop, monitorBottom, monitorWidth, monitorHeight
    local monitorIndex := getMonitorAt(
        windowX,
        windowY,
        &monitorLeft,
        &monitorTop,
        &monitorRight,
        &monitorBottom,
        &monitorWidth,
        &monitorHeight
    )

    local centeredX := (monitorWidth - windowWidth) / 2 + monitorLeft
    local centeredY := (monitorHeight - windowHeight) / 2 + monitorTop

    if (debug) {
        ; Printing special characters:
        ;   Newlines: `n
        ;   Tab character: `t
        MsgBox(
            "Window:"
            "`n(" windowX ", " windowY ")"
            "`n" windowWidth "x" windowHeight

            "`n`nCentered Window`n"
            "(" centeredX ", " centeredY ")"

            "`n`nMonitor: " monitorIndex
            "`n Left=" monitorLeft
            "`n Top=" monitorTop
            "`n Right=" monitorRight
            "`n Bottom=" monitorBottom
            "`n Width=" monitorWidth
            "`n Height=" monitorHeight
        ,
            ; A_ScreenWidth and A_ScreenHeight only work for primary display
            "screenW=" A_ScreenWidth
            ", screenH=" A_ScreenHeight
        )
    }

    ; Window width and height are optional, i.e. the call below is equivalent unless resizing the window
    ; WinMove(centeredX, centeredY,,, windowId)
    WinMove(centeredX, centeredY, windowWidth, windowHeight, windowId)

    ; If the window occasionally becomes unfocused, uncomment the line below to force-refocus it
    ; WinActivate("ahk_id" windowId)
}



; Reference variables for setting their values within the function.
; Easier than returning an array since spreading arrays doesn't exist with AutoHotKey v2.
;
; See:
;   - Variables and (de-)referencing: https://www.autohotkey.com/docs/v2/Variables.htm
;   - Example: https://www.autohotkey.com/boards/viewtopic.php?style=1&t=101478
getMonitorAt(
    winX,
    winY,
    monitorLeftRef,
    monitorTopRef,
    monitorRightRef,
    monitorBottomRef,
    monitorWidthRef,
    monitorHeightRef
) {
    global debug

    ; Alternative: https://www.autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor
    ;
    ; SysGet, Mon, Monitor, %A_Index%
    ; SysGet docs: https://www.autohotkey.com/docs/v2/lib/SysGet.htm
    ; SysGet, m, MonitorCount
    ; if (winX >= MonLeft && winX <= MonRight && winY >= MonTop && winY <= MonBottom) {
    ;     return A_Index
    ; }

    local numMonitors := MonitorGetCount()
    local primaryMonitor := MonitorGetPrimary()

    ; Iterate through all monitors.
    Loop numMonitors {
        local monLeft, monTop, monRight, monBottom
        local monWorkLeft, monWorkTop, monWorkRight, monWorkBottom

        MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        MonitorGetWorkArea(A_Index, &monWorkLeft, &monWorkTop, &monWorkRight, &monWorkBottom)

        local monWidth := monRight - monLeft
        local monWorkWidth := monWorkRight - monWorkLeft
        local monHeight := monBottom - monTop
        local monWorkHeight := monWorkBottom - monWorkTop

        if (debug) {
            MsgBox(
                " Monitor: " A_Index
                "`n Name: " MonitorGetName(A_Index)
                "`n monLeft: " monLeft "`t(monWorkLeft=" monWorkLeft ")"
                "`n monRight: " monRight "`t(monWorkRight=" monWorkRight ")"
                "`n monTop: " monTop "`t(monWorkTop=" monWorkTop ")"
                "`n monBottom: " monBottom "`t(monWorkBottom=" monWorkBottom ")"
                "`n monWidth: " monWidth "`t(monWorkWidth=" monWorkWidth ")"
                "`n monHeight: " monHeight "`t(monWorkHeight=" monWorkHeight ")"
                ,
                "Monitor dimensions"
            )
        }

        ; Check if the window is on this monitor, and set vars/return if so.
        if (winX >= monLeft && winX <= monRight && winY >= monTop && winY <= monBottom) {
            %monitorLeftRef% := monLeft
            %monitorTopRef% := monTop
            %monitorRightRef% := monRight
            %monitorBottomRef% := monBottom
            %monitorWidthRef% := monWidth
            %monitorHeightRef% := monHeight

            return A_Index
        }
    }

    ; Default monitor index to primary display
    return 1
}
