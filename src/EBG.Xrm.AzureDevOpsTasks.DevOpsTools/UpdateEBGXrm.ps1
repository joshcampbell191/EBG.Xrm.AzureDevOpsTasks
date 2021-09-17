#
# UpdateEBGXrm.ps1
#

param
(
	[string]$SourcePath
)

$ErrorActionPreference = "Stop"

#Script Location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Script Path: $scriptPath"

$targetPath = "$scriptPath\Lib\EBGXrm\1.0.0"

$scriptsPath = "$SourcePath\EBG.Xrm.PowerShell.Scripts\*.ps1"
Copy-Item -Path $scriptsPath -Destination $targetPath

$cmdletsPath = "$SourcePath\EBG.Xrm.PowerShell.Cmdlets\bin\Release\net472\*.dll"
Copy-Item -Path $cmdletsPath -Destination $targetPath

$cmdletsPath = "$SourcePath\EBG.Xrm.PowerShell.Cmdlets\bin\Release\net472\*.xslt"
Copy-Item -Path $cmdletsPath -Destination $targetPath

