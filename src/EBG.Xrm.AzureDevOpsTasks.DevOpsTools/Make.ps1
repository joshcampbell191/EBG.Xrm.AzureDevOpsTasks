#
# Make.ps1
#
# Run this script to generate the tasks folder structure and extension
#

$ErrorActionPreference = "Stop"

Write-Host "Packaging EBG DevOps Tools"

#Script Location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Write-Host "Script Path: $scriptPath"


#Creating output directory
$OutputDir = $scriptPath + "\bin"

if (Test-Path $OutputDir)
{
	Remove-Item $OutputDir -Force -Recurse
}

New-Item $OutputDir -ItemType directory | Out-Null

#Creating temp directory
$TempDir = $scriptPath + "\temp"

if (Test-Path $TempDir)
{
	Remove-Item $TempDir -Force -Recurse
}

New-Item $TempDir -ItemType directory | Out-Null

#Copy Extension Files
Copy-Item .\icon_128x128.png $OutputDir -Force -Recurse
Copy-Item .\license.txt $OutputDir -Force -Recurse
Copy-Item .\overview.md $OutputDir -Force -Recurse
Copy-Item .\vss-extension.json $OutputDir -Force -Recurse
#Copy-Item .\Images $OutputDir -Force -Recurse
#Copy-Item .\Screenshots $OutputDir -Force -Recurse

#Copy Initial Tasks
Copy-Item -Path .\Tasks -Destination $OutputDir -Recurse

$tasks = Get-ChildItem .\Tasks -directory

foreach($task in $tasks)
{
	Copy-Item -Path .\icon.png -Destination "$OutputDir\Tasks\$task"
	New-Item "$OutputDir\Tasks\$task\ps_modules\VstsTaskSdk" -ItemType directory | Out-Null
	Copy-Item -Path .\Lib\VstsTaskSdk\0.11.0\*.* -Destination "$OutputDir\Tasks\$task\ps_modules\VstsTaskSdk"
}

#EBGToolInstaller
$taskName = "EBGToolInstaller"
New-Item "$OutputDir\Tasks\$taskName\Lib\Nuget\5.9.1" -ItemType directory | Out-Null
Copy-Item -Path .\Lib\Nuget\5.9.1\*.* -Destination "$OutputDir\Tasks\$taskName\Lib\Nuget\5.9.1"
New-Item "$OutputDir\Tasks\$taskName\Lib\EBGXrm\1.0.0" -ItemType directory | Out-Null
Copy-Item -Path .\Lib\EBGXrm\1.0.0\*.* -Destination "$OutputDir\Tasks\$taskName\Lib\EBGXrm\1.0.0"

#Clean Up
Remove-Item $TempDir -Force -Recurse
