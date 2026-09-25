@echo off
rem ShowPlayPI: removes all partitions of this SD card and creates one empty partition (the card is like new).
rem Asks for confirmation and administrator rights; works only on the ShowPlayPI card it is started from.
rem Everything runs in one line: the card this file is on is changed while it runs.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clear-sd-card.ps1" -Drive %~d0 & exit /b
