# Copy Sources

This powershell script is designed for moving processed photos and copying RAW files from cameras.

## Folder structure

Supposed, that you have two folders, one for processed photos and another for archive, and photoshop action saves your photos to the processed folder.

Processed folder looks like this:

```text
C:\Your\Processed\Folder → your small-fize JPEG photos, PSDs, TIFFs and others are here.
└───FS → full-fize files are here.
```

Archive folders looks like this:

```text
D:\PhotoArch → archive root.
├───2021 → year
├───2022
|   ├───08 → month
|   └───12
|       └───23 → day
|          ├───FS → full-size files
|          └───RAW → raw files
└───2023
```

### Json config file

Your config file must be:

* Valid json file.
* Stored in your home/profile directory with name 'CopySourcesConf.json'
* Based on 'ConfSample.json' file, distributed with this script

If there are no 'CopySourcesConf.json' in your home/profile folder, it will be copied there from ConfSample.

One config file can contains information about multiple cameras. It`s higghly recommended to have separate archive roots for each camera.
