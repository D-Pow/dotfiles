#NoEnv
SetBatchLines -1

OnMessage(0xFF, "InputHandler")
RegisterRawInputDevices(1, 6)
Esc::ExitApp

InputHandler(wParam, lParam) {
    static RID_INPUT        := 0x10000003
    static RIDI_DEVICENAME  := 0x20000007

    Critical

    DllCall("GetRawInputData"
        , "Ptr",    lParam
        , "UInt",   RID_INPUT
        , "Ptr",    0
        , "UIntP",  size
        , "UInt",   8 + A_PtrSize * 2)
    VarSetCapacity(buffer, size)
    DllCall("GetRawInputData"
        , "Ptr",    lParam
        , "UInt",   RID_INPUT
        , "Ptr",    &buffer
        , "UIntP",  size
        , "UInt",   8 + A_PtrSize * 2)

    devHandle := NumGet(buffer, 8)
    vk := NumGet(buffer, 8 + 2 * A_PtrSize + 6, "UShort")

    DllCall("GetRawInputDeviceInfo"
        , "Ptr",    devHandle
        , "UInt",   RIDI_DEVICENAME
        , "Ptr",    0
        , "UIntP",  size)
    VarSetCapacity(info, size)
    DllCall("GetRawInputDeviceInfo"
        , "Ptr",    devHandle
        , "UInt",   RIDI_DEVICENAME
        , "Ptr",    &info
        , "UIntP",  size)

    ToolTip % "tick:`t" A_TickCount
        . "`nname:`t"   StrGet(&info)
        . "`nvk:`t"     vk
}

RegisterRawInputDevices(usagePage, usage) {
    static RIDEV_INPUTSINK := 0x00000100
    VarSetCapacity(rawDevice, 8 + A_PtrSize)
    NumPut(usagePage,       rawDevice, 0, "UShort")
    NumPut(usage,           rawDevice, 2, "UShort")
    NumPut(RIDEV_INPUTSINK, rawDevice, 4, "UInt")
    NumPut(A_ScriptHWND,    rawDevice, 8, "UPtr")

    if !DllCall("RegisterRawInputDevices"
        , "Ptr",  &rawDevice
        , "UInt", 1
        , "UInt", 8 + A_PtrSize)
    {
        throw "Fail"
    }
}