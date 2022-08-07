:: Opens Steam in BigPicture mode
:: Useful for creating custom key combos and/or controller bindings to basically Alt+Tab out of a game
:: If running in CMD, you have to add & at the front
::
:: See:
::  - Steam command: https://www.reddit.com/r/linux_gaming/comments/24r1v8/comment/ch9ugqj
::  - Executing files with spaces in their paths: https://stackoverflow.com/questions/39101129/call-exe-from-batch-file-with-variable-path-containing-spaces
::  - PATH in Windows: https://superuser.com/questions/1216658/path-environment-variable-windows-10-echo-path-on-command-prompt-shows-only/1216661#1216661
::  - Comments in .bat files: https://stackoverflow.com/questions/11269338/how-to-comment-out-add-comment-in-a-batch-cmd
::  - `chmod a+x` equivalent in Windows: https://stackoverflow.com/questions/6818031/use-shebang-hashbang-in-windows-command-prompt/6818266#6818266

:: Prevents the cmd window from appearing when executing the file
@echo off

:: Steam command
"C:\Program Files (x86)\Steam\steam.exe" steam://open/bigpicture
