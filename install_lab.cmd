@echo off
REM =============================================================================
REM  install_lab.cmd - Windows-friendly launcher for install_lab.sh
REM
REM  Use this from cmd, PowerShell or Windows Terminal:
REM      install_lab.cmd
REM      install_lab.cmd --no-up --count 3
REM
REM  Why this exists: typing "bash install_lab.sh" in a normal Windows shell
REM  often runs the WSL launcher stub (C:\Windows\System32\bash.exe) and fails
REM  with "Windows Subsystem for Linux has no installed distributions", because
REM  Git's bin directory is not on PATH. This finds a real bash instead.
REM =============================================================================
setlocal enabledelayedexpansion

set "BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe"      set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined BASH if exist "C:\msys64\usr\bin\bash.exe" set "BASH=C:\msys64\usr\bin\bash.exe"

if not defined BASH (
  echo.
  echo   x No bash found.
  echo.
  echo   This script needs Git Bash. Install Git for Windows:
  echo     https://git-scm.com/download/win
  echo.
  echo   Or run it from inside a WSL shell, where bash is the real thing.
  echo.
  exit /b 1
)

"%BASH%" "%~dp0install_lab.sh" %*
exit /b %ERRORLEVEL%
