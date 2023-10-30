@echo off
REM MJC 10-21-22
SET "_LOGDIR=%~dp0Logs"
SET "_LOGPREFIX=jamf2snipe"
SET "_LOGFILEPATH=%_LOGDIR%\%_LOGPREFIX%_%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%.log"
pushd "%~dp0"
call "%~dp0.virtualenv\jamf2snipe\Scripts\activate.bat"
echo ********************************************************** >> "%_LOGFILEPATH%"
echo ** LOG START: %DATE% %TIME% >> "%_LOGFILEPATH%"
python jamf2snipe -v -r >> "%_LOGFILEPATH%" 2>&1
REM Forward any errors detected in log file.
powershell.exe -NoProfile -Windowstyle Hidden -ExecutionPolicy Bypass -File "forward-errorlogs.ps1"
popd

