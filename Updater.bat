@echo off
cls
cd %~dp0
powershell -ExecutionPolicy ByPass -File "%~dp0sources\Updater.ps1"
pause