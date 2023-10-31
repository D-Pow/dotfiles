; #Requires AutoHotkey v2.0


#+up:: {
    local windowId := WinActive("A")

    WinMaximize(windowId)
}

#up:: {
    ; Do nothing
}
