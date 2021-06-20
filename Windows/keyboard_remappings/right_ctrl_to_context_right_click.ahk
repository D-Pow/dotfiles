#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; TODO Does not work. See: https://autohotkey.com/board/topic/101461-strange-behaviour-of-ralt-key/
; Is it case sensitive? Maybe try rCtrl
; Is the map-to entry (after ::) functional or literal? If literal, that would explain why this
;   doesn't work b/c key is mapped to another key which is mapped to another key

Insert::NumLock
NumLock::RCtrl
RCtrl::AppsKey
