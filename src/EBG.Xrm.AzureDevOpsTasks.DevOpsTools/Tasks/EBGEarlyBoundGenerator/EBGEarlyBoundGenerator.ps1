[CmdletBinding()]

param()

$ErrorActionPreference = "Stop"

Write-Verbose 'Entering EBGEarlyBoundGenerator.ps1'

#Inputs
$crmConnectionString = Get-VstsInput -Name crmConnectionString -Require
$settingsPath = Get-VstsInput -Name settingsPath -Require
$creationType = Get-VstsInput -Name creationType
$executeAsync = Get-VstsInput -Name executeAsync -AsBool

#EBG Tools
$ebgToolsPath = $env:EBG_Tools_Path
Write-Verbose "EBG Tools Path: $ebgToolsPath"

if (-not $ebgToolsPath)
{
	Write-Error "EBG_Tools_Path not found. Add 'EBG Tool Installer' before this task."
}

."$ebgToolsPath\EBGToolsFunctions.ps1"

$earlyBoundGeneratorAPI = 'DLaB.Xrm.EarlyBoundGenerator.Api'
$earlyBoundGeneratorAPIInfo = Get-EBGTool -toolName $earlyBoundGeneratorAPI
$earlyBoundGeneratorAPIInfoPath = "$($earlyBoundGeneratorAPIInfo.Path)"

& "$ebgToolsPath\EBGXrm\1.0.0\InvokeEarlyBoundGenerator.ps1" -CrmConnectionString $crmConnectionString -SettingsPath $settingsPath -CreationType $creationType -ExecuteAsync $executeAsync -EarlyBoundGeneratorApiPath $earlyBoundGeneratorAPIInfoPath

Write-Verbose 'Leaving EBGEarlyBoundGenerator.ps1'