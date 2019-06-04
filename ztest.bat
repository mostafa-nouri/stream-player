for /f "delims=" %%x in (config.txt) do (set "%%x")
set PATH=%PATH%;%mpvpath%

bash.exe playall.sh zlinks.txt 720
pause
