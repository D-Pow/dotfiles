; #Requires AutoHotkey v2.0

DetectHiddenWindows false  ; Don't enumerate hidden windows

; Less reliable
global WindowGui := Gui("+Resize", "Window List")
global enumWindowsOutput := WindowGui.Add("ListView", "x5 y0 w400 h500", ["PID", "Title", "WindowID", "Class"])

global DesktopWindowGui := Gui("+Resize", "Desktop List")
global enumDesktopWindowsOutput := DesktopWindowGui.Add("ListView", "x5 y0 w400 h500", ["PID", "Title", "WindowID", "Class"])

global ProcessesWindowGui := Gui("+Resize", "Process List")
global processesWindowsOutput := ProcessesWindowGui.Add("ListView", "x2 y0 w400 h500", ["Process Name", "PID", "WindowID", "Command Line"])

global output := ""


; Make Windows minimize action behave like Linux in that minimized windows drop to the
; bottom of the z-index (i.e. Alt+Tab list)
;
; See:
;   - https://www.autohotkey.com/board/topic/91577-taskbarnavigation-switch-windows-in-taskbar-order-alt-tab-replacement/
minimizeWindowAndLowerZindex() {
    local windowId := WinActive("A")
    local windowClass := WinGetClass("A")
    local activeProcessName := WinGetProcessName("A")

    ; RegExMatch(".*\.exe$")

    local windowList := WinGetList()
    local lastWindowId := WinGetIDLast()
    local lastWindowPos := WinGetPos()
    local titles := WinGetTitle()

    s := ""
    for i,v in windowlist {
        s := s " " i "-" v
        ; MsgBox(, i "-" v)
    }

    local GW_HWNDNEXT := 2

    ; local next := DllCall("GetWindow", "")

    ; RegisterCallback("handleEnumWindowsProcess",,, Visible)
    local callbackEnumWindows := CallbackCreate(handleEnumWindowsProcess, "F")
    local callbackDesktopWindows := CallbackCreate(handleDesktopWindowProcess, "F")
    ; MsgBox(callback)
    ; DllCall("EnumWindows", "Ptr", callback, "Ptr", 0)

    ; Requesting `EnumDesktopWindows` with 0 results in getting all window data across all desktops (workspaces?).
    ; Actually produces the most amount of data, so is very useful for arbitrary commands
    ; See: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdesktopwindows?redirectedfrom=MSDN
    DllCall("EnumDesktopWindows", "Ptr", 0, "Ptr", callbackEnumWindows, "Ptr", 0)

    ; Getting the correct desktop window ID seems to not output any windows for some reason
    local desktopWindowId := DllCall("GetDesktopWindow")
    DllCall("EnumDesktopWindows", "Ptr", desktopWindowId, "Ptr", callbackDesktopWindows, "Ptr", 0)

    global WindowGui, DesktopWindowGui, ProcessesWindowGui, processesWindowsOutput, output
    WindowGui.Show("AutoSize")
    DesktopWindowGui.Show("AutoSize")

    ; MsgBox(output, "Output")
    ; MsgBox(titles, "Titles")
    ; MsgBox(windowId "-" windowList[1] "-" lastWindowId "-" lastWindowPos)

    ; local done := 0

    local windowedProcesses := []
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process") {
        ; if (done == 0) {
        ;     s := ""
        ;     size := ""
        ;     ; size := ObjDump(process, ByRef s, 0)
        ;     ; ObjSetBase(process, Object)
        ;     for k,v in process.SystemProperties_
        ;         s .= " -- k.name=" k.Name
        ;         ; s .= ",k.value" k.Value
        ;         ; s .= ",v=" v
        ;     MsgBox(s ".." size ".." , "Process obj")
        ;     done := 1
        ; }
        local winId := ""
        local winPid := process.ProcessId
        local exeName := process.Name
        local cmdLine := process.CommandLine


        if (WinExist("ahk_pid" process.ProcessId)) {
            winId := WinGetId("ahk_pid" process.ProcessId)
            windowedProcesses.Push({ winPid: winPid, winId: winId, exeName: exeName, cmdLine: cmdLine })
            ; windowedProcesses.Push(process)
        }
        processesWindowsOutput.Add("", exeName, winPid, winId, cmdLine)
    }

    ProcessesWindowGui.Show("AutoSize")
    ; MsgBox(windowedProcesses.Length " [0]:" windowedProcesses[1])

    for i,windowedProcess in windowedProcesses {
        local winPid := windowedProcess.winPid
        local winId := windowedProcess.winId
        local exeName := windowedProcess.exeName
        local cmdLine := windowedProcess.cmdLine

        local winTitle := WinGetTitle(winId)

        if (StrLen(winTitle) > 0) {
            winTitle := cmdLine
        }

        MsgBox("PID=" winPid ", WinID=" winId ", Title=" winTitle, "Windowed App")
    }




    ; Other attempts:

    ; DllCall("SetWindowPos", windowId, windowId "" 1)
    ; DllCall("SetWindowPos", "int", windowId, "int", lastWindowId)
    ; DllCall("SetWindowPos", "Ptr", windowId, "Ptr", windowList[windowList.Length - 1])
    ; DllCall("SetWindowPos", "int", windowId, "int", windowId "" 1)
    ; DllCall("SetWindowPos", "int", windowId, "int", windowList[windowList.Length])

    ; WinSet("Bottom", windowId)
    ; MsgBox(, ControlGetIndex(windowClass))

    ; WinMinimize(windowId)
    ; WinMoveBottom("ahk_id" windowId)
}

handleDesktopWindowProcess(windowId, something) {
    local windowTitle := WinGetTitle(windowId)

    if (StrLen(windowTitle) > 0) {
        local winPid := WinGetPID(windowId)
        local windowClass := WinGetClass(windowId)

        enumDesktopWindowsOutput.Add("", winPid, windowTitle, windowId, windowClass)
    }

    return true
}

handleEnumWindowsProcess(windowId, something) {
    global enumWindowsOutput

    local windowTitle := WinGetTitle(windowId)

    if (StrLen(windowTitle) > 0) {
        local winPid := WinGetPID(windowId)
        local windowClass := WinGetClass(windowId)

        enumWindowsOutput.Add("", winPid, windowTitle, windowId, windowClass)
    }

    return true
}


#m:: {
    minimizeWindowAndLowerZindex()
}
