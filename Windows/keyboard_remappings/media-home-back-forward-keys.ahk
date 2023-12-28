; #Requires AutoHotkey v2.0


Browser_Home:: {
    Send "{Media_Play_Pause}"
}

Browser_Forward:: {
    Send "{Media_Next}"
}

Browser_Back:: {
    Send "{Media_Prev}"
}


; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; whatfile := "macro.ahk"

; Loop {
;     Input, Var, L1 V E, {LButton},{enter}
;
;     text:="`nSend {" Var "} `n"
;     text2:="Sleep, " 20 "`n"
;
;     FileAppend,
;     (
;       %text%
;       %text2%
;     ), %whatfile%
; }
