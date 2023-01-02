Set-Location (Split-Path $PSScriptRoot -Parent)
ps2exe -inputFile .\source\Copy-Sources.ps1 -outputFile .\Copy-Sources.exe -iconFile .\res\Camera.ico -version 0.1.6.19 -STA -noConsole -noVisualStyles