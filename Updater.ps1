[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

if (
    (Test-Path ([System.IO.Path]::Combine($PSScriptRoot,'.git'))) -and
    (& {try {git} catch {$false}})
) {
    Set-Location $PSScriptRoot
    git pull --rebase
    $Message = "Updated from git repository"
}
else {
    $ZipLink = 'https://github.com/AleksejEgorov/CopySources/archive/refs/heads/master.zip'
    $ArchFile = [System.IO.Path]::Combine($env:TEMP,'CopySources-master.zip')
    Invoke-WebRequest -Uri $ZipLink -OutFile $ArchFile
    Expand-Archive -Path $ArchFile -DestinationPath $env:TEMP -Force
    Copy-Item -Path [System.IO.Path]::Combine($env:TEMP,'CopySources-master','*') -Destination $PSScriptRoot -Recurse -Force
    $Message = "Updated from downloaded zip file"
    Remove-Item ([System.IO.Path]::Combine($env:TEMP,'CopySources-master')) -Recurse -Force
    Remove-Item $ArchFile -Force
}

$Form = [System.Windows.Forms.Form]::new()
$Form.TopMost = $true
[System.Windows.Forms.MessageBox]::Show(
    $Form,
    $Message,
    'Copy sources',
    'OK',
    'Info'
)