@echo off
cls
cd %~dp0
powershell -ExecutionPolicy ByPass -File "%~dp0source\Updater.ps1"
pause