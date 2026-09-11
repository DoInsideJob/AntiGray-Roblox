@echo off
setlocal enabledelayedexpansion

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo === NSLookup to Hosts Editor ===
echo.

echo Running: nslookup tr.rbxcdn.com 9.9.9.9
echo.
nslookup tr.rbxcdn.com 9.9.9.9
echo.

:: Save nslookup output to temp file
nslookup tr.rbxcdn.com 9.9.9.9 > "%temp%\ns_out.txt" 2>nul

set "targetip="

:: Parse each line looking for first IPv4 address
for /f "usebackq delims=" %%L in ("%temp%\ns_out.txt") do (
    if not defined targetip call :check_line "%%L"
)

del "%temp%\ns_out.txt" >nul 2>&1

if not defined targetip (
    echo Error: No IPv4 address found.
    exit /b 1
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

echo.
echo Successfully added to hosts:
echo %targetip% tr.rbxcdn.com
exit /b

:check_line
set "ln=%~1"
if "!ln!"=="" exit /b
:: Skip DNS server section (Server: and Address: singular, NOT Addresses:)
echo !ln!| findstr /i /b "Server:" >nul 2>&1 && exit /b
echo !ln!| findstr /i /b /c:"Address: " >nul 2>&1 && exit /b
:: Check each word for IPv4 pattern
for %%W in (!ln!) do (
    echo %%W| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul 2>&1
    if not errorlevel 1 (
        set "targetip=%%W"
        exit /b
    )
)
exit /b
