@echo off
setlocal enabledelayedexpansion

:: Define log file path
set logfile=D:\ProxyTools\sing-box\bootProxy.log

:: Function to get current timestamp
for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set hour=%%a
    set minute=%%b
    set second=%%c
    set centisecond=%%d
)
set timestamp=%date% %hour%:%minute%:%second%.%centisecond%

:: Log the start of the script
echo [%timestamp%] Script started >> %logfile%

:: Get the IP address of the current network interface
for /f "tokens=*" %%o in ('powershell -c "(Invoke-RestMethod -Uri 'http://ip-api.com/json/%ip%?fields=org').org"') do (
    set "operator=%%o"
    set timestamp=%date% %time%
    echo [%timestamp%] Operator detected: !operator! >> %logfile%
)

if not "%operator:Mobile=%"=="%operator%" (
    set timestamp=%date% %time%
    echo [%timestamp%] Mobile >> %logfile%
    set configFile=config.hk.jsonc
) else if not "%operator:Telecom=%"=="%operator%" (
    set timestamp=%date% %time%
    echo [%timestamp%] Telecom >> %logfile%
    set configFile=config.us.jsonc
) else if not "%operator:Unicom=%"=="%operator%" (
    set timestamp=%date% %time%
    echo [%timestamp%] Unicom >> %logfile%
    set configFile=config.us.jsonc
) else (
    set timestamp=%date% %time%
    echo [%timestamp%] Other >> %logfile%
    set configFile=config.us.jsonc
)

echo [%timestamp%] Using config file: %configFile% >> %logfile%

:: Check if 'sing-box' is running
tasklist /FI "IMAGENAME eq sing-box.exe" 2>NUL | find /I /N "sing-box.exe">NUL
if "%ERRORLEVEL%"=="0" (
    set timestamp=%date% %time%
    echo [%timestamp%] 'sing-box' is running, closing it... >> %logfile%
    taskkill /F /IM sing-box.exe >> %logfile%
    set timestamp=%date% %time%
    echo [%timestamp%] Rebooting 'sing-box'... >> %logfile%
    @REM start "" "d:\path\to\sing-box.exe" >> %logfile%  :: Correct this path
) else (
    set timestamp=%date% %time%
    echo [%timestamp%] 'sing-box' is not running, booting it... >> %logfile%
    @REM start "" "d:\path\to\sing-box.exe" >> %logfile%  :: Correct this path
)

D:
cd D:\ProxyTools\sing-box
start D:\ProxyTools\sing-box\RunHiddenConsole.exe D:\ProxyTools\sing-box\sing-box.exe run -c %configFile%"

:: Log the end of the script
set timestamp=%date% %time%
echo [%timestamp%] Script ended >> %logfile%

endlocal