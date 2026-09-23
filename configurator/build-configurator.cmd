@echo off
rem Compiles the Windows configurator and puts the EXE where the image copies it
rem onto the USB drive (rootfs\usr\share\showplaypi\usb\).
rem Requirement: AutoIt3 is installed.
setlocal
set AUT2EXE=%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe_x64.exe
if not exist "%AUT2EXE%" set AUT2EXE=%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe_x64.exe
if not exist "%AUT2EXE%" (
    echo AutoIt3 was not found.
    exit /b 1
)
set OUT=%~dp0..\rootfs\usr\share\showplaypi\usb\ShowPlayPI-Configurator.exe
"%AUT2EXE%" /in "%~dp0ShowPlayPI-Configurator.au3" /out "%OUT%" /icon "%~dp0ShowPlayPI-Configurator.ico" /x64
if errorlevel 1 exit /b 1
echo Created: %OUT%
