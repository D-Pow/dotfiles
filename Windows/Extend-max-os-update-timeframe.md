This will allow you to select any length of time for OS update delays, even beyond the 5 week standard cap.

[Ref](https://www.elevenforum.com/t/have-you-ever-wanted-to-pause-updates-past-the-5-week-limit.12798)

* In `RegEdit`, go to:
    - `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`
    - Create new DWORD (32-bit) value: `FlightSettingsMaxPauseDays`
    - Value:
        + `Decimal`
        + `365`
