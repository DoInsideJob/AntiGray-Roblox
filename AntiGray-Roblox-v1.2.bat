@echo off
setlocal enabledelayedexpansion

:: Auto-elevate to admin if not already
net session >nul 2>&1
if %errorlevel% neq 0 (
    if "%~1"=="--silent" (
        powershell -Command "Start-Process '%~f0' -ArgumentList '--silent','\"%~2\"' -Verb RunAs"
    ) else (
        powershell -Command "Start-Process '%~f0' -Verb RunAs"
    )
    exit /b
)

:: If launched with --silent, run fix directly without menu
if "%~1"=="--silent" goto :fix_silent

:menu
cls
echo ========================================
echo       AntiGray By DoInsideJob
echo ========================================
echo.
echo 1. Fix Roblox
echo 2. Turn on autostart when Windows start
echo 3. Turn off autostart
echo 4. I'm lazy, just give me play Roblox
echo 0. Exit
echo.
set /p "choice=Enter your choice: "

if "%choice%"=="1" goto :fix
if "%choice%"=="2" goto :autostart_on
if "%choice%"=="3" goto :autostart_off
if "%choice%"=="4" goto :fix_lazy
if "%choice%"=="0" exit /b
echo Invalid choice. Try again.
timeout /t 2 >nul
goto :menu

:fix
cls
echo === NSLookup to Hosts Editor ===
echo.

:: Run nslookup ONCE, save to temp file
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul

:: Display the SAME output from file
type "%temp%\ns_out.txt"
echo.

:: Collect all IPv4 addresses into a list from the SAME file
set "ipcount=0"
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    call :check_line "%%L"
)

del "%temp%\ns_out.txt" >nul 2>&1

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

:: Show numbered list WITH actual IPs (max 10)
echo.
echo ========================================
echo Available IPv4 addresses:
echo ========================================
echo.
for /l %%N in (1,1,%ipcount%) do (
    echo %%N. !ip[%%N]!
)
echo 0. Exit
echo.
set /p "ipchoice=Enter your choice: "

:: Check if user chose exit
if "%ipchoice%"=="0" goto :menu

:: Validate input
set "valid=0"
for /l %%N in (1,1,%ipcount%) do (
    if "%ipchoice%"=="%%N" set "valid=1"
)
if "%valid%"=="0" (
    echo Invalid choice.
    timeout /t 2 >nul
    goto :menu
)

set "targetip=!ip[%ipchoice%]!"

echo.
echo Selected: %targetip%
echo.

set "hostsfile=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts_tmp"

:: Remove old entry if exists
findstr /i /c:"tr.rbxcdn.com" "%hostsfile%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i /v /c:"tr.rbxcdn.com" "%hostsfile%" > "%tempfile%"
    copy /y "%tempfile%" "%hostsfile%" >nul 2>&1
    del "%tempfile%" >nul 2>&1
)

:: Append new entry
echo %targetip% tr.rbxcdn.com>> "%hostsfile%"

echo Successfully added to hosts:
echo %targetip% tr.rbxcdn.com
echo.
pause
goto :menu

:fix_lazy
cls
echo === NSLookup to Hosts Editor ===
echo.

:: Run nslookup ONCE, save to temp file
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul

:: Display the SAME output
type "%temp%\ns_out.txt"
echo.

:: Find first IPv4 address from the SAME file
set "targetip="
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    if not defined targetip call :check_line_lazy "%%L"
)

del "%temp%\ns_out.txt" >nul 2>&1

if not defined targetip (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

echo Found IP: %targetip%
echo.

set "hostsfile=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts_tmp"

:: Remove old entry if exists
findstr /i /c:"tr.rbxcdn.com" "%hostsfile%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i /v /c:"tr.rbxcdn.com" "%hostsfile%" > "%tempfile%"
    copy /y "%tempfile%" "%hostsfile%" >nul 2>&1
    del "%tempfile%" >nul 2>&1
)

:: Append new entry
echo %targetip% tr.rbxcdn.com>> "%hostsfile%"

echo Successfully added to hosts:
echo %targetip% tr.rbxcdn.com
echo.
pause
goto :menu

:fix_silent
:: %2 = IP index number chosen during autostart setup
set "ipindex=%~2"
if not defined ipindex set "ipindex=1"

cls
echo === NSLookup to Hosts Editor ===
echo.

:: Run nslookup ONCE, save to temp file
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul

:: Display the SAME output
type "%temp%\ns_out.txt"
echo.

:: Collect all IPv4 addresses into a list from the SAME file
set "ipcount=0"
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    call :check_line "%%L"
)

del "%temp%\ns_out.txt" >nul 2>&1

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    exit /b 1
)

:: Use the IP at the chosen index, or first if index too high
set "targetip="
if defined ip[%ipindex%] (
    set "targetip=!ip[%ipindex%]!"
)
if not defined targetip (
    set "targetip=!ip[1]!"
)

echo Using IP #%ipindex%: %targetip%
echo.

set "hostsfile=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts_tmp"

:: Remove old entry if exists
findstr /i /c:"tr.rbxcdn.com" "%hostsfile%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i /v /c:"tr.rbxcdn.com" "%hostsfile%" > "%tempfile%"
    copy /y "%tempfile%" "%hostsfile%" >nul 2>&1
    del "%tempfile%" >nul 2>&1
)

:: Append new entry
echo %targetip% tr.rbxcdn.com>> "%hostsfile%"

echo Successfully added to hosts:
echo %targetip% tr.rbxcdn.com
exit /b

:autostart_on
cls
set "startup=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "scriptpath=%~f0"

if exist "%startup%\RobloxFixer.bat" (
    echo Autostart already exists.
    echo.
    pause
    goto :menu
)

echo === Select IP for Autostart ===
echo.

:: Run nslookup ONCE, save to temp file
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul

:: Display the SAME output
type "%temp%\ns_out.txt"
echo.

:: Collect all IPv4 addresses into a list from the SAME file
set "ipcount=0"
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    call :check_line "%%L"
)

del "%temp%\ns_out.txt" >nul 2>&1

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

:: Show numbered list WITHOUT actual IPs (max 10)
echo.
echo ========================================
echo Available IPv4 addresses:
echo ========================================
echo.
for /l %%N in (1,1,%ipcount%) do (
    echo %%N. %%N IP
)
echo 0. Exit
echo.
set /p "ipchoice=Enter your choice: "

:: Check if user chose exit
if "%ipchoice%"=="0" goto :menu

:: Validate input
set "valid=0"
for /l %%N in (1,1,%ipcount%) do (
    if "%ipchoice%"=="%%N" set "valid=1"
)
if "%valid%"=="0" (
    echo Invalid choice.
    timeout /t 2 >nul
    goto :menu
)

:: Save the IP INDEX (not the IP itself) into the launcher
(
    echo @echo off
    echo start "" "%scriptpath%" --silent %ipchoice%
) > "%startup%\RobloxFixer.bat"

if %errorlevel% equ 0 (
    echo.
    echo Autostart created successfully.
    echo File: %startup%\RobloxFixer.bat
    echo Selected: IP #%ipchoice% ^(will re-query on boot^)
    echo Mode: silent ^(no menu, direct fix^)
) else (
    echo Error: Failed to create autostart entry.
)
echo.
pause
goto :menu

:autostart_off
cls
set "startup=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "autofile=%startup%\RobloxFixer.bat"

if not exist "%autofile%" (
    echo Autostart is not active.
    echo.
    pause
    goto :menu
)

del "%autofile%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Autostart disabled. File removed.
) else (
    echo Error: Failed to remove autostart file.
)
echo.
pause
goto :menu

:check_line
set "ln=%~1"
if "!ln!"=="" exit /b
echo !ln!| findstr /i /b "Server:" >nul 2>&1 && exit /b
echo !ln!| findstr /i /b /c:"Address: " >nul 2>&1 && exit /b
for %%W in (!ln!) do (
    echo %%W| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
    if not errorlevel 1 (
        if %ipcount% LSS 10 (
            set /a "ipcount+=1"
            set "ip[!ipcount!]=%%W"
        )
    )
)
exit /b

:check_line_lazy
set "ln=%~1"
if "!ln!"=="" exit /b
echo !ln!| findstr /i /b "Server:" >nul 2>&1 && exit /b
echo !ln!| findstr /i /b /c:"Address: " >nul 2>&1 && exit /b
for %%W in (!ln!) do (
    echo %%W| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
    if not errorlevel 1 (
        set "targetip=%%W"
        exit /b
    )
)
exit /b
