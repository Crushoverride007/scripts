@echo off
REM =============================================================================
REM  install_vm.cmd - Windows-friendly launcher for install_vm.sh
REM
REM      install_vm.cmd --desktop
REM      install_vm.cmd --server --name my-vm --ram 4096 --cpus 2
REM
REM  Finds a real bash (Git Bash) instead of the WSL launcher stub, which is
REM  what "bash" resolves to in a normal Windows shell.
REM =============================================================================
setlocal enabledelayedexpansion

set "BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe"      set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined BASH if exist "C:\msys64\usr\bin\bash.exe" set "BASH=C:\msys64\usr\bin\bash.exe"

if not defined BASH (
  echo.
  echo   x No bash found. Install Git for Windows: https://git-scm.com/download/win
  echo.
  exit /b 1
)

"%BASH%" "%~dp0install_vm.sh" %*
exit /b %ERRORLEVEL%
