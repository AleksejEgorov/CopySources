[CmdletBinding()]
param(
    [switch]$Major,
    [switch]$Minor
)

Set-Location (Split-Path $PSScriptRoot -Parent)
[version]$Version = (Get-Item .\Copy-Sources.exe).VersionInfo.ProductVersion
Write-Host -ForegroundColor Yellow "Current version is $Version"

$NewVersion = [version]::new()
if ($Major) {
    $NewVersion = [version]::new($Version.Major + 1,0,0,$Version.Revision + 1)
}
elseif ($Minor) {
    $NewVersion = [version]::new($Version.Major,$Version.Minor + 1,0,$Version.Revision + 1)
}
else {
    $NewVersion = [version]::new($Version.Major,$Version.Minor,$Version.Build + 1,$Version.Revision + 1)
}

Write-Host -ForegroundColor Yellow "New version is $NewVersion"

Remove-Item .\Copy-Sources.exe
# Remove-Item .\Updater.exe
ps2exe -inputFile .\source\Copy-Sources.ps1 -outputFile .\Copy-Sources.exe -iconFile .\res\Camera.ico -version $NewVersion.ToString() -STA -noConsole -noVisualStyles
# ps2exe -inputFile .\source\Updater.ps1 -outputFile .\Updater.exe -iconFile .\res\Updater.ico -version $NewVersion.ToString() -STA -noVisualStyles