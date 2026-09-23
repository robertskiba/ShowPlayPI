@echo off
rem Builds a ShowPlayPI image in WSL (Ubuntu). Output: build\out\ShowPlayPI-*.img.xz
wsl -u root --cd "%~dp0" -- bash build/build.sh %*
pause
