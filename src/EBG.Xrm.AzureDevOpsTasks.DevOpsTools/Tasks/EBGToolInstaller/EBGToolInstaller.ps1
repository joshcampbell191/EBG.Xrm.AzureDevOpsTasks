[CmdletBinding()]

param()

$ErrorActionPreference = "Stop"

Write-Verbose 'Entering EBGToolInstaller.ps1'

#Inputs
$nugetFeed = Get-VstsInput -Name nugetFeed -Require
$nugetSource = Get-VstsInput -Name nugetSource
$nugetUsername = Get-VstsInput -Name nugetUsername
$nugetPassword = Get-VstsInput -Name nugetPassword
$nugetUseProxy = Get-VstsInput -Name nugetUseProxy -AsBool
$ebgApiVersion = Get-VstsInput -Name ebgApiVersion

#Script Location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Script Path: $scriptPath"
Write-Verbose "env VSTS_TOOLS_PATH: $env:VSTS_TOOLS_PATH"
Write-Verbose "env AGENT_TOOLSDIRECTORY: $env:AGENT_TOOLSDIRECTORY"
Write-Verbose "env AGENT_WORKFOLDER: $env:AGENT_WORKFOLDER"
Write-Verbose "env AGENT_TEMPDIRECTORY: $env:AGENT_TEMPDIRECTORY"
Write-Verbose "env TEMP: $env:TEMP"

#Tool Directory
if ($env:AGENT_TOOLSDIRECTORY)
{
	$toolPath = $env:AGENT_TOOLSDIRECTORY
}
elseif ($env:VSTS_TOOLS_PATH)
{
	$toolPath = $env:VSTS_TOOLS_PATH
}
else
{
	$toolPath = $env:AGENT_WORKFOLDER + "\tools"
}
Write-Host "Using Tools Path: $toolPath"

$frameworkCache = $toolPath + "\EBGTools"
Write-Verbose "Framework Cache: $frameworkCache"

$taskVersion = $(ConvertFrom-Json (Get-Content -Path .\task.json -Raw)).Version
$taskFullVersion = "$($taskVersion.Major).$($taskVersion.Minor).$($taskVersion.Patch)"

Write-Verbose "Current Task Version: $taskFullVersion"

$currentVersion = $($taskVersion.Major)
$currentVersionPath = "$frameworkCache\$taskFullVersion"

Write-Host "Tools Directory: $currentVersionPath"

Write-Host "##vso[task.setvariable variable=EBG_Tools_Path]$currentVersionPath"
$env:EBG_Tools_Path = $currentVersionPath
Write-Host "##vso[task.setvariable variable=EBG_Tools_Task_Version]$currentVersion"

if (Test-Path $frameworkCache)
{
	Write-Verbose "$frameworkCache already created"
}
else
{
	New-Item "$frameworkCache" -ItemType directory | Out-Null
}

if (Test-Path $currentVersionPath)
{
	Write-Verbose "$currentVersion already cached" | Out-Null
}
else
{
	New-Item "$currentVersionPath" -ItemType directory | Out-Null
	Copy-Item -Path "$scriptPath\Lib\**" -Destination $currentVersionPath -Force -Recurse

	Write-Verbose "Lib Copy completed"
}

."$scriptPath\EBGToolsFunctions.ps1"

#Temp Directory
if ($env:AGENT_TEMPDIRECTORY)
{
	$tempDir = $env:AGENT_TEMPDIRECTORY
}
else
{
	$tempDir = $env:TEMP
}
$tempDir =  "$tempDir\$(New-Guid)"
New-Item $tempDir -ItemType directory | Out-Null
Write-Verbose "Using Temp Directory: $tempDir"

#Nuget Path
$nugetPath = "$currentVersionPath\NuGet\5.9.1\nuget.exe"
$nugetConfigPath = "$tempDir\nuget.config"

Copy-Item -Path "$scriptPath\*nuget.config" -Destination "$tempDir"
Copy-Item -Path "$scriptPath\Tools.json" -Destination "$currentVersionPath" -Force
Copy-Item -Path "$scriptPath\EBGToolsFunctions.ps1" -Destination "$currentVersionPath" -Force

#Proxy

if ($nugetUseProxy)
{
	Write-Verbose "Attempting to use agent proxy settings for nuget feed"

	$nugetProxyUrl = $env:AGENT_PROXYURL
	$nugetProxyUsername = $env:AGENT_PROXYUSERNAME
	$nugetProxyPassword = $env:AGENT_PROXYPASSWORD
}
else
{
	Write-Verbose "Skipping using agent proxy settings for nuget feed"
}

#Nuget Feed
if ($nugetFeed -eq 'official')
{
	Write-Verbose "Using offical Nuget source"

	$nugetSource = 'https://api.nuget.org/v3/index.json'
	$nugetUsername = ''
	$nugetPassword = ''
}
elseif ($nugetFeed -eq 'custom')
{
	Write-Verbose "Using custom Nuget source"
}
else
{
	throw "Unknown nuget source: $nugetFeed"
}

$params = @{
	nugetPath = "$nugetPath"
	nugetConfigPath = "$nugetConfigPath"
	sourceName = "Nuget"
	source = "$nugetSource"
	username = "$nugetUsername"
	password = "$nugetPassword"
	nugetProxyUrl = "$nugetProxyUrl"
	nugetProxyUsername = "$nugetProxyUsername"
	nugetProxyPassword = "$nugetProxyPassword"
}

Configure-Nuget @params

Write-Host "##vso[task.setvariable variable=$nugetConfigVariable]$nugetConfigPath"

$env:EBG_Tools_NugetConfig_Path = $nugetConfigPath

Set-EBGToolVersionVariable -toolName 'DLaB.Xrm.EarlyBoundGenerator.Api' -version $ebgApiVersion

Write-Verbose 'Leaving EBGToolInstaller.ps1'
