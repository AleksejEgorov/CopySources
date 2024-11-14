<#
    Exit codes:
    0 — Success
    1 — Config or exiftool import error
    2 — Source detection error
#>

[CmdletBinding()]
param (
    # Parameter help description
    [Parameter(
        Mandatory = $false,
        Position = 0
    )]
    [string]$ConfJsonPath
)


begin {
    Import-Module -Name Storage -Verbose:$false
    Write-Verbose "Invokation start"
    #region Form creation
        [void]([System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'))
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        # [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        # $MessageBox = [System.Windows.Forms.MessageBox]
        $Form = [System.Windows.Forms.Form]::new()
        $Form.Text = "Copy Sources"
        $Form.Size = [System.Drawing.Size]::new(480,160)
        $Form.FormBorderStyle = 'Fixed3D'
        $Form.MaximizeBox = $false
        $Form.MinimizeBox = $false
        $Form.StartPosition = "CenterScreen"
        $Form.TopMost = $true

        $Label = [System.Windows.Forms.Label]::new()
        $Label.Location = [System.Drawing.Point]::new(10,20)
        $Label.Size = [System.Drawing.Size]::new(440,20)

        $Label.Text = 'Execution started'
        $Form.Controls.Add($Label)

        $ProgressBar = [System.Windows.Forms.ProgressBar]::new()
        $ProgressBar.Location = [System.Drawing.Size]::new(10,80)
        $ProgressBar.Size = [System.Drawing.Size]::new(440,20)
        $ProgressBar.Minimum = 0
        $ProgressBar.Maximum = 100
        $Form.Controls.Add($ProgressBar)

        $Form.Add_Shown({$Form.Activate()})
    #endregion

    if ((Get-ChildItem $PSScriptRoot).Name -contains 'Readme.md') {
        $ProjectRoot = $PSScriptRoot
    }
    elseif ((Get-Item $PSScriptRoot).Name -eq 'source') {
        $ProjectRoot = Split-Path $PSScriptRoot -Parent
    }

    $IconFilePath = [System.IO.Path]::Combine($ProjectRoot,'res','Camera.ico')
    Write-Verbose "Icon $IconFilePath"

    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($IconFilePath)
    $Form.Icon = $Icon

    $Form.Show()



    # Import config
    try {
        if (!$ConfJsonPath) {
            $ConfJsonPath = [System.IO.Path]::Combine($HOME,'CopySourcesConf.json')
            if (!(Test-Path $ConfJsonPath)) {
                Copy-Item ([System.IO.Path]::Combine($ProjectRoot,'configs','ConfSample.json')) $ConfJsonPath
                [void]([System.Windows.Forms.MessageBox]::Show(
                    $Form,
                    "Config was copied from sample to $ConfJsonPath`nChange it with your values and run again.",
                    'Copy sources',
                    'OK',
                    'Warning'
                ))
                exit 1
            }
        }
        $Conf = Get-Content -Path $ConfJsonPath -Raw | ConvertFrom-Json
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $Form,
            "Cannot inport config file. $($Error[0].Exception.Message)",
            'Copy sources',
            'OK',
            'Error'
        )
        $Form.Close()
        $Form.Dispose()
        exit 1
    }
    $Label.Text = "Config path: $ConfJsonPath"

    #Test exif tool exists
    $ExifTool = [System.IO.Path]::Combine($ProjectRoot,'bin','exiftool.exe')

    if (!(Test-Path $ExifTool)) {
        $ExifToolArchive = [System.IO.Path]::Combine($env:TEMP,'exiftool.zip')
        Invoke-WebRequest -Uri $Conf.$ExifToolUrl -OutFile $ExifToolArchive
        Expand-Archive -Path $ExifToolArchive -DestinationPath $ProjectRoot -Force
        Rename-Item -Path ([System.IO.Path]::Combine($ProjectRoot,'exiftool(-k).exe')) -NewName 'exiftool.exe'
        Remove-Item $ExifToolArchive
        try {
            [void](Get-Item -Path $ExifTool)
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                $Form,
                "Cannot load exiftool.exe. $($Error[0].Exception.Message)",
                'Copy sources',
                'OK',
                'Error'
            )
            exit 1
        }
    }
}

process {

    $ResultVolumes = @()

    do {
        $Volumes = @(Get-Volume)
    } while (!$Volumes)

    Write-Verbose "Step 0: $($Volumes.Count)"

    foreach ($Camera in $Conf.Cameras) {
        # Define SD card
        $CamVolumes = $Volumes

        # Step 1: Drive types
        if ($Camera.SDMarks.DriveTypes) {
            $CamVolumes = @($CamVolumes | Where-Object {$PSItem.DriveType -in $Camera.SDMarks.DriveTypes})
        }
        Write-Verbose "Step 1: $($CamVolumes.Count)"

        # Step 2: Volume labels
        if ($Camera.SDMarks.Labels) {
            $CamVolumes = @($CamVolumes | Where-Object {$PSItem.FileSystemLabel -in $Camera.SDMarks.Labels})
        }
        Write-Verbose "Step 2: $($CamVolumes.Count)"

        # Step 3: Item in root directory
        if ($Camera.SDMarks.FSItems) {
            $FoundVolumes = @()

            foreach ($Volume in $CamVolumes) {

                foreach ($TestItemName in $Camera.SDMarks.FSItems) {
                    if (
                        ((Get-ChildItem (Get-PSDrive $Volume.DriveLetter).Root).Name -contains $TestItemName) -and
                        ($FoundVolumes.UniqueId -notcontains $Volume.UniqueId)
                    ) {
                        $FoundVolumes += $Volume
                    }
                }
            }

            $CamVolumes = $FoundVolumes
        }
        Write-Verbose "Step 3: $($CamVolumes.Count)"

        foreach ($CamVolume in $CamVolumes) {
            if ($ResultVolumes.UniqueId -notcontains $CamVolume.UniqueId) {
                $ResultVolumes += $CamVolume
            }
        }
    }

    switch ($ResultVolumes.Count) {
        0 {
            [void]([System.Windows.Forms.MessageBox]::Show(
                $Form,
                "No source drive found.",
                'Copy sources',
                'OK',
                'Error'
            ))
            $Form.Close()
            $Form.Dispose()
            exit 2
        }
        1 {
            $SourceRoot = (Get-PSDrive $Volume[0].DriveLetter).Root
            Write-Verbose "Sorce root is $SourceRoot"
        }
        Default {
            [void]([System.Windows.Forms.MessageBox]::Show(
                $Form,
                "Multiple drives matched all conditions found.`nRemove drives or change config file",
                'Copy sources',
                'OK',
                'Warning'
            ))
            # TODO: @AleksejEgorov Add volume selection for this case.
            $Form.Close()
            $Form.Dispose()
            exit 2
        }
    }


    $SourceContent = @(Get-ChildItem -Path $SourceRoot -Recurse -File)
    Write-Verbose "$SourceRoot contains $($SourceContent.Count) files."

    $ProdContent = @(
        Get-ChildItem -Path $Conf.ProdFolder -File | `
        Where-Object {$PSItem.Extension -in $Conf.ProcessedExtensions} |
        # jpeg will bw processed earlier than psd.
        Sort-Object {$PSItem.Name.Length},{$PSItem.Name}
    )
    $ProgressBar.Maximum = $ProdContent.Count

    [int]$Counter = 0
    [int]$ProgressCounter = 0

    foreach ($Photo in $ProdContent) {
        $ProgressCounter++
        $Label.Text = $Photo.Name
        $ProgressBar.Value = $ProgressCounter
        $Form.Update()


        if (!(Test-Path $Photo.FullName)) {
            Write-Verbose "Photo $($Photo.Name) was processed previously"
            continue
        }


        Write-Verbose "Processing $($Photo.Name)."
        $PhotoBaseName = $Photo.Name.Split('.',' ','-','_','(')[0]
        Write-Verbose "Base name is $PhotoBaseName."

        # Get exif
        $Exif = & $ExifTool -lang en -csv $Photo.FullName | ConvertFrom-Csv
        Write-Verbose "Taken with $($Exif.Model)"
        if ($Exif.Model -notin $Conf.Cameras.Model) {
            continue
            Write-Verbose "Skipped."
        }
        else {
            $ArchiveRoot = ($Conf.Cameras | Where-Object {$PSItem.Model -eq $Exif.Model}).ArchFolder
            $RawExtensions = ($Conf.Cameras | Where-Object {$PSItem.Model -eq $Exif.Model}).RawExtensions
            Write-Verbose "Processing."
        }

        $DateTaken = [datetime]::ParseExact($Exif.DateTimeOriginal,'yyyy:MM:dd HH:mm:ss',$null)


        # Discover raw files.
        $PhotoRaw = @()
        $SourceContent | `
        Where-Object {
            ($PSItem.Extension -in $RawExtensions) -and
            ($PSItem.Name -like "$PhotoBaseName*")
        } | ForEach-Object {
            if ((& $ExifTool -lang en -csv $PSItem.FullName | ConvertFrom-Csv).Model -eq $Exif.Model) {
                $PhotoRaw += $PSItem
                Write-Verbose "Raw $($PSItem.FullName) found."
            }
            else {
                Write-Verbose "Skip $($PSItem.FullName). It was not taken with $($Exif.Model)."
                continue
            }
        }

        if (!$PhotoRaw) {
            Write-Warning "Raw for $PhotoBaseName not found"
            continue
        }

        Write-Verbose "Taken on $DateTaken."
        $Year = [string]$DateTaken.Year
        $Month = ([string]$DateTaken.Month).PadLeft(2,'0')
        $Day = ([string]$DateTaken.Day).PadLeft(2,'0')

        $ArchiveFolder = [System.IO.Path]::Combine($ArchiveRoot,$Year,$Month,$Day)
        $ArchiveFolderFS = [System.IO.Path]::Combine($ArchiveFolder,"FS")
        $ArchiveFolderRaw = [System.IO.Path]::Combine($ArchiveFolder,"RAW")

        Write-Verbose "Base destination folder is : $ArchiveFolder"
        Write-Verbose "Full size destination folder is : $ArchiveFolderFS"
        Write-Verbose "Raw files destination folder is : $ArchiveFolderRaw"

        # Checking destination folder in archive directory. If not exist - creating.
        if (!(Test-Path $ArchiveFolder)) {
            [void](New-Item -ItemType Directory $ArchiveFolder)
            [void](New-Item -ItemType Directory $ArchiveFolderFS)
            [void](New-Item -ItemType Directory $ArchiveFolderRaw)

            Write-Verbose "Directories created."
        }

        # Moving processed files (small jped and other)
        Get-ChildItem -Path $Conf.ProdFolder -File | `
        Where-Object {
            ($PSItem.Extension -in $Conf.ProcessedExtensions) -and
            ($PSItem.Name -like "$PhotoBaseName*")
        } | ForEach-Object {
            Move-Item -Path $PSItem.FullName -Destination $ArchiveFolder -Force
            Write-Verbose "Moving $($PSItem.FullName)."
        }


        # Moving processed full-size photos
        Get-ChildItem -Path ([System.IO.Path]::Combine($Conf.ProdFolder,'FS')) -File | `
        Where-Object {
            ($PSItem.Extension -in $Conf.ProcessedExtensions) -and
            ($PSItem.Name -like "$PhotoBaseName*")
        } | ForEach-Object {
            Move-Item -Path $PSItem.FullName -Destination $ArchiveFolderFS -Force
            Write-Verbose "Moving $($PSItem.FullName)."
        }

        # Copying raw
        $PhotoRaw | ForEach-Object {
            Copy-Item -Path $PSItem.FullName -Destination $ArchiveFolderRaw -Force
            Write-Verbose "Copying raw $($PSItem.FullName)"
        }


        $Counter++
        Write-Verbose "$Counter photos done."
        $Label.Text = "$Counter complete."
    }
}

end {
    $Label.Text = "$Counter complete."
    $Form.Update()
    if ($Counter -gt 0) {
        $Message = "Processing done. $Counter photos total."
    }
    else {
        $Message = "Nothing to be have."
    }
    Write-Verbose $Message

    [void]([System.Windows.Forms.MessageBox]::Show(
        $Form,
        $Message,
        'Copy sources',
        'ok',
        'Information'
    ))
    $Form.Close()
    $Form.Dispose()

}