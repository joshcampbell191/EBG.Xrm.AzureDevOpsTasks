#
# InvokeEarlyBoundGenerator.ps1
#

param(
	[string]$CrmConnectionString,
	[string]$SettingsPath,
	[string]$CreationType,
	[string]$EarlyBoundGeneratorApiPath
)

$ErrorActionPreference = "Stop"

Write-Verbose 'Entering InvokeEarlyBoundGenerator.ps1' -Verbose

#Parameters
Write-Verbose "CrmConnectionString = $CrmConnectionString"
Write-Verbose "SettingsPath = $SettingsPath"
Write-Verbose "CreationType = $CreationType"
Write-Verbose "EarlyBoundGeneratorApiPath = $EarlyBoundGeneratorApiPath"

#Script Location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Script Path: $scriptPath"

#Load EBGXrm
$ebgXrm = $scriptPath + "\EBG.Xrm.PowerShell.Cmdlets.dll"
Write-Verbose "Importing EBGXrm: $ebgXrm"
Import-Module $ebgXrm
Write-Verbose "Imported EBGXrm"

Write-Host "Invoking Early Bound Generator: $CreationType"

Invoke-EarlyBoundGenerator -ConnectionString $CrmConnectionString -SettingsPath $SettingsPath -CreationType $CreationType -EarlyBoundGeneratorApiPath $EarlyBoundGeneratorApiPath

Write-Host "Invoked Early Bound Generator"

Write-Verbose 'Leaving InvokeEarlyBoundGenerator.ps1' -Verbose