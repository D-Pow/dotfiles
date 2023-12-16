; #Requires AutoHotkey v2.0


^!T:: {
    local wslExeFile := EnvGet("USERPROFILE") "\AppData\Local\Microsoft\WindowsApps\wsl.exe"
    local gitBashExeFile := "C:\Program Files\Git\git-bash.exe"

    if (FileExist(wslExeFile)) {
        Run "%wslExeFile% --cd" "~"
    } else if (FileExist(gitBashExeFile)) {
        local workingDir := ""
        local options := ""
        local pid := ""

        Run(gitBashExeFile, workingDir, options, &pid)

        try {
            WinActivate("ahk_id", pid)
        } catch Error as err {
            ; Do nothing if window-focus fails
        }
    } else {
        Send "^!T"
    }
}
