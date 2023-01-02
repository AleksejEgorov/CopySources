@echo off
cls
cd %~dp0
powershell -ExecutionPolicy ByPass -File .\sources\Updater.ps1
pause