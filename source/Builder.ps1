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
    $Major = $Version.Major + 1
    $Minor = 0
    $Build = 0
}
elseif ($Minor) {
    $Major = $Version.Major
    $Minor = $Version.Minor + 1
    $Build = 0
}
else {
    $Major = $Version.Major
    $Minor = $Version.Minor
    $Build = $Version.Build + 1
}
$Revision = $Version.Revision + 1

$NewVersion = [version]::new($Major,$Minor,$Build,$Revision)

Write-Host -ForegroundColor Yellow "New version is $NewVersion"


ps2exe -inputFile .\source\Copy-Sources.ps1 -outputFile .\Copy-Sources.exe -iconFile .\res\Camera.ico -version $NewVersion.ToString() -STA -noConsole -noVisualStyles
ps2exe -inputFile .\source\Updater.ps1 -outputFile .\Updater.exe -iconFile .\res\Updater.ico -version $NewVersion.ToString() -STA -noVisualStyles