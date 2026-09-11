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

:: Extract version from bat filename (e.g. AntiGray_v2.0.bat -> 2.0)
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$n = [System.IO.Path]::GetFileNameWithoutExtension('%~n0'); if ($n -match '(\d+(\.\d+){0,2})') { $matches[1] } else { '0' }"`) do set "SCRIPT_VERSION=%%V"
if not defined SCRIPT_VERSION set "SCRIPT_VERSION=0"

:: Load settings (two lines: restart_roblox, check_updates)
set "settingsfile=%APPDATA%\RobloxFixer_settings.txt"
set "restart_roblox=1"
set "check_updates=1"
if exist "%settingsfile%" (
    set /p "restart_roblox=" < "%settingsfile%"
    set "line2="
    for /f "usebackq skip=1 delims=" %%A in ("%settingsfile%") do if not defined line2 set "line2=%%A"
    if defined line2 set "check_updates=!line2!"
)

:: If launched with --silent, run fix directly without menu
if "%~1"=="--silent" goto :fix_silent

:: Check for updates (interactive mode only, if enabled)
if "%check_updates%"=="1" call :check_updates

:menu
cls
echo ========================================
echo       AntiGray By DoInsideJob  v%SCRIPT_VERSION%
echo ========================================
echo.
echo 1. Fix Roblox
echo 2. Turn on autostart when Windows start
echo 3. Turn off autostart
echo 4. I'm lazy, just give me play Roblox
if "%restart_roblox%"=="1" (
    echo 5. Restart Roblox after fix: ON
) else (
    echo 5. Restart Roblox after fix: OFF
)
if "%check_updates%"=="1" (
    echo 6. Auto-update: ON
) else (
    echo 6. Auto-update: OFF
)
echo 0. Exit
echo.
set /p "choice=Enter your choice: "

if "%choice%"=="1" goto :fix
if "%choice%"=="2" goto :autostart_on
if "%choice%"=="3" goto :autostart_off
if "%choice%"=="4" goto :fix_lazy
if "%choice%"=="5" goto :toggle_restart
if "%choice%"=="6" goto :toggle_updates
if "%choice%"=="0" exit /b
echo Invalid choice. Try again.
timeout /t 2 >nul
goto :menu

:save_settings
(
    echo %restart_roblox%
    echo %check_updates%
) > "%settingsfile%"
exit /b

:toggle_restart
if "%restart_roblox%"=="1" (
    set "restart_roblox=0"
    echo Restart Roblox after fix: OFF
) else (
    set "restart_roblox=1"
    echo Restart Roblox after fix: ON
)
call :save_settings
echo Setting saved.
echo.
pause
goto :menu

:toggle_updates
if "%check_updates%"=="1" (
    set "check_updates=0"
    echo Auto-update: OFF
) else (
    set "check_updates=1"
    echo Auto-update: ON
)
call :save_settings
echo Setting saved.
echo.
pause
goto :menu

:check_updates
echo Checking for updates...
set "gh_api=https://api.github.com/repos/DoInsideJob/AntiGray-Roblox/releases/latest"
set "versionfile=%APPDATA%\RobloxFixer_version.txt"

powershell -NoProfile -Command "try { $r = Invoke-RestMethod -Uri '%gh_api%' -Headers @{'User-Agent'='batch'} -TimeoutSec 10; $r.tag_name | Out-File '%temp%\gh_tag.txt' -Encoding ascii; if ($r.assets.Count -gt 0) { $r.assets[0].browser_download_url | Out-File '%temp%\gh_url.txt' -Encoding ascii; $r.assets[0].name | Out-File '%temp%\gh_asset.txt' -Encoding ascii } else { '' | Out-File '%temp%\gh_url.txt' -Encoding ascii; '' | Out-File '%temp%\gh_asset.txt' -Encoding ascii } } catch { 'ERROR' | Out-File '%temp%\gh_tag.txt' -Encoding ascii }"

set "latest_tag="
if exist "%temp%\gh_tag.txt" set /p "latest_tag=" < "%temp%\gh_tag.txt"
del "%temp%\gh_tag.txt" >nul 2>&1

if "%latest_tag%"=="ERROR" (
    echo Could not check for updates. Continuing...
    timeout /t 2 >nul
    exit /b
)
if "%latest_tag%"=="" (
    echo Could not check for updates. Continuing...
    timeout /t 2 >nul
    exit /b
)

set "latest_clean=%latest_tag%"
if /i "%latest_clean:~0,1%"=="v" set "latest_clean=%latest_clean:~1%"

set "skipped_version="
if exist "%versionfile%" set /p "skipped_version=" < "%versionfile%"
if /i "%latest_tag%"=="%skipped_version%" exit /b

powershell -NoProfile -Command "try { $installed = [version]'%SCRIPT_VERSION%'; $latest = [version]'%latest_clean%'; if ($latest -gt $installed) { 'UPDATE' | Out-File '%temp%\gh_compare.txt' -Encoding ascii } else { 'NOUPDATE' | Out-File '%temp%\gh_compare.txt' -Encoding ascii } } catch { 'ERROR' | Out-File '%temp%\gh_compare.txt' -Encoding ascii }"

set "compare_result="
if exist "%temp%\gh_compare.txt" set /p "compare_result=" < "%temp%\gh_compare.txt"
del "%temp%\gh_compare.txt" >nul 2>&1

if "%compare_result%"=="ERROR" (
    echo Could not compare versions. Continuing...
    timeout /t 2 >nul
    exit /b
)
if not "%compare_result%"=="UPDATE" exit /b

echo.
echo New version is out! You wanna download %latest_tag% now? Y/N
echo.
set /p "updchoice=Enter choice: "
if /i "%updchoice%"=="Y" (
    set "dl_url="
    if exist "%temp%\gh_url.txt" set /p "dl_url=" < "%temp%\gh_url.txt"
    set "asset_name="
    if exist "%temp%\gh_asset.txt" set /p "asset_name=" < "%temp%\gh_asset.txt"

    if "!dl_url!"=="" (
        echo No downloadable asset found. Opening release page in browser...
        start "" "https://github.com/DoInsideJob/AntiGray-Roblox/releases/latest"
    ) else (
        echo Downloading !asset_name!...
        powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!dl_url!' -OutFile '%temp%\!asset_name!' -TimeoutSec 30 } catch { exit 1 }"
        if exist "%temp%\!asset_name!" (
            move /y "%temp%\!asset_name!" "%~f0" >nul 2>&1
            if exist "%temp%\!asset_name!" del "%temp%\!asset_name!" >nul 2>&1
            echo %latest_tag%> "%versionfile%"
            del "%temp%\gh_url.txt" >nul 2>&1
            del "%temp%\gh_asset.txt" >nul 2>&1
            echo Update installed! Restarting...
            timeout /t 2 >nul
            start "" "%~f0"
            exit /b
        ) else (
            echo Download failed. You can download manually from:
            echo https://github.com/DoInsideJob/AntiGray-Roblox/releases/latest
            timeout /t 5 >nul
        )
    )
    del "%temp%\gh_url.txt" >nul 2>&1
    del "%temp%\gh_asset.txt" >nul 2>&1
) else (
    echo %latest_tag%> "%versionfile%"
    del "%temp%\gh_url.txt" >nul 2>&1
    del "%temp%\gh_asset.txt" >nul 2>&1
    echo Update skipped. You won't be prompted again for %latest_tag%.
    timeout /t 2 >nul
)
exit /b

:do_lookup
:: --- 1. nslookup (displayed) ---
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul
type "%temp%\ns_out.txt"
echo.

:: Parse nslookup IPs
set "ipcount=0"
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    call :check_line "%%L"
)
del "%temp%\ns_out.txt" >nul 2>&1

:: --- 2. curl Google DNS JSON (silent, no display) ---
where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -s -H "accept: application/dns-json" "https://dns.google/resolve?name=tr.rbxcdn.com" > "%temp%\curl_out.txt" 2>nul
) else (
    powershell -NoProfile -Command "try { Invoke-RestMethod -Uri 'https://dns.google/resolve?name=tr.rbxcdn.com' -Headers @{'accept'='application/dns-json'} -TimeoutSec 10 | ConvertTo-Json -Compress | Out-File '%temp%\curl_out.txt' -Encoding ascii } catch { '' | Out-File '%temp%\curl_out.txt' -Encoding ascii }"
)

:: Parse curl JSON IPs silently
if exist "%temp%\curl_out.txt" (
    powershell -NoProfile -Command "try { $j = Get-Content '%temp%\curl_out.txt' -Raw | ConvertFrom-Json; if ($j.Answer) { $j.Answer | Where-Object { $_.data -match '^\d+\.\d+\.\d+\.\d+$' } | ForEach-Object { $_.data } | Out-File '%temp%\curl_ips.txt' -Encoding ascii } else { '' | Out-File '%temp%\curl_ips.txt' -Encoding ascii } } catch { '' | Out-File '%temp%\curl_ips.txt' -Encoding ascii }"
    if exist "%temp%\curl_ips.txt" (
        for /f "usebackq delims=" %%I in ("%temp%\curl_ips.txt") do (
            call :add_ip "%%I"
        )
        del "%temp%\curl_ips.txt" >nul 2>&1
    )
    del "%temp%\curl_out.txt" >nul 2>&1
)
exit /b

:fix
cls
echo === NSLookup to Hosts Editor ===
echo.

call :do_lookup

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

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

if "%ipchoice%"=="0" goto :menu

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

call :write_hosts "%targetip%"
call :post_fix

echo.
pause
goto :menu

:fix_lazy
cls
echo === NSLookup to Hosts Editor ===
echo.

call :do_lookup

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

set "targetip=!ip[1]!"
echo Found IP: %targetip%
echo.

call :write_hosts "%targetip%"
call :post_fix

echo.
pause
goto :menu

:fix_silent
set "ipindex=%~2"
if not defined ipindex set "ipindex=1"

cls
echo === NSLookup to Hosts Editor ===
echo.

call :do_lookup

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    exit /b 1
)

set "targetip="
if defined ip[%ipindex%] (
    set "targetip=!ip[%ipindex%]!"
)
if not defined targetip (
    set "targetip=!ip[1]!"
)

echo Using IP #%ipindex%: %targetip%
echo.

call :write_hosts "%targetip%"
call :post_fix

exit /b

:write_hosts
set "hostsfile=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts_tmp"

findstr /i /c:"tr.rbxcdn.com" "%hostsfile%" >nul 2>&1
if %errorlevel% equ 0 (
    findstr /i /v /c:"tr.rbxcdn.com" "%hostsfile%" > "%tempfile%"
    copy /y "%tempfile%" "%hostsfile%" >nul 2>&1
    del "%tempfile%" >nul 2>&1
)

echo %~1 tr.rbxcdn.com>> "%hostsfile%"

echo Successfully added to hosts:
echo %~1 tr.rbxcdn.com
exit /b

:post_fix
echo.
echo === Post-fix: killing Roblox, clearing cache, flushing DNS ===
echo.

set "was_running=0"
tasklist /FI "IMAGENAME eq RobloxPlayerBeta.exe" 2>nul | find /I "RobloxPlayerBeta.exe" >nul
if %errorlevel% equ 0 set "was_running=1"

taskkill /F /IM RobloxPlayerBeta.exe >nul 2>&1
taskkill /F /IM RobloxPlayerLauncher.exe >nul 2>&1
echo Roblox process terminated ^(if was running^).

set "rbx_cache=%TEMP%\Roblox"
if exist "%rbx_cache%" (
    del /q /f /s "%rbx_cache%\*" >nul 2>&1
    for /d %%D in ("%rbx_cache%\*") do rmdir /s /q "%%D" >nul 2>&1
    echo Roblox cache cleared: %rbx_cache%
) else (
    echo Roblox cache folder not found ^(already clean^).
)

ipconfig /flushdns
echo.
echo Post-fix complete.

if "%was_running%"=="1" (
    if "%restart_roblox%"=="1" (
        echo.
        echo === Relaunching Roblox ===
        set "rbx_exe="
        set "rbx_versions=C:\Program Files\Roblox\Versions"
        if exist "%rbx_versions%" (
            for /d %%D in ("%rbx_versions%\version-*") do (
                if exist "%%D\RobloxPlayerBeta.exe" set "rbx_exe=%%D\RobloxPlayerBeta.exe"
            )
        )
        if defined rbx_exe (
            echo Launching: !rbx_exe!
            start "" "!rbx_exe!"
            echo Roblox relaunched.
        ) else (
            echo Roblox executable not found in %rbx_versions%.
            echo Please launch Roblox manually.
        )
    ) else (
        echo.
        echo Restart Roblox setting is OFF. Skipping relaunch.
    )
) else (
    echo.
    echo Roblox was not running before fix. No relaunch needed.
)
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

call :do_lookup

if "%ipcount%"=="0" (
    echo Error: No IPv4 address found.
    echo.
    pause
    goto :menu
)

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

if "%ipchoice%"=="0" goto :menu

set "valid=0"
for /l %%N in (1,1,%ipcount%) do (
    if "%ipchoice%"=="%%N" set "valid=1"
)
if "%valid%"=="0" (
    echo Invalid choice.
    timeout /t 2 >nul
    goto :menu
)

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
        if !ipcount! LSS 20 (
            set "dup=0"
            for /l %%N in (1,1,!ipcount!) do (
                if /i "!ip[%%N]!"=="%%W" set "dup=1"
            )
            if "!dup!"=="0" (
                set /a "ipcount+=1"
                set "ip[!ipcount!]=%%W"
            )
        )
    )
)
exit /b

:add_ip
:: %1 = IP from curl JSON to add (with dedup check, max 20)
echo %~1| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 exit /b
if %ipcount% GEQ 20 exit /b
set "dup=0"
for /l %%N in (1,1,%ipcount%) do (
    if /i "!ip[%%N]!"=="%~1" set "dup=1"
)
if "!dup!"=="0" (
    set /a "ipcount+=1"
    set "ip[!ipcount!]=%~1"
)
exit /b
