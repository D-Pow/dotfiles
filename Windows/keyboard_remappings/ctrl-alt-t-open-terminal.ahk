; #Requires AutoHotkey v2.0


^!T:: {
    local wslExeFile := EnvGet("USERPROFILE") "\AppData\Local\Microsoft\WindowsApps\wsl.exe"

    if (FileExist(wslExeFile)) {
        Run "%wslExeFile% --cd" "~"
    } else {
        Send "^!T"
    }
}
