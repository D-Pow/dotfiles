#!/usr/bin/env bash

# See:
#   - Passing multi-line commands to PowerShell: https://stackoverflow.com/questions/2608144/how-to-split-long-commands-over-multiple-lines-in-powershell/2608186#2608186
#   - How to tell if GlobalProtect VPN is active on Windows: https://live.paloaltonetworks.com/t5/globalprotect-discussions/checking-if-globalprotect-status-is-active-connected-via-script/td-p/534841
#   - Native Linux - Tell if logged in via VPN: https://askubuntu.com/questions/219724/how-can-i-see-if-im-logged-in-via-vpn
powershell.exe -Command '
    Get-NetAdapter `
        | Where-Object { $_.InterfaceDescription -like "PANGP Virtual Ethernet Adapter*" } `
        | Select-Object Status
    ' \
    | awk '{
        lineToPrint = lineToPrint >= 0 ? lineToPrint : -1;

        if ($1 ~ /\s*Status\s*/) {
            lineToPrint = NR + 2;
        };

        if (NR == lineToPrint) {
            print($0);
        };
    }' \
    | grep -Piq 'Up'
