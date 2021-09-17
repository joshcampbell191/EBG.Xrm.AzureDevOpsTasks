#
# EBGToolsFunctions.ps1
#

$ErrorActionPreference = "Stop"

Write-Verbose 'Entering EBGToolsFunctions.ps1'

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$nugetConfigVariable = 'EBG_Tools_NugetConfig_Path'

function Execute-Nuget
{
	param(
		[string]$nugetPath,
		[string[]]$nugetArgList,
		[switch]$returnOutput
	)

	Write-Verbose "Nuget command: $nugetPath $nugetArgList"

	if ($returnOutput)
	{
		$output = & $nugetPath $nugetArgList

		if ($output)
		{
			foreach ($line in $output)
			{
				Write-Verbose $line
			}
		}

		Write-Output $output
	}
	else
	{
		& $nugetPath $nugetArgList
	}

	if ($lastexitcode -ne 0)
	{
		throw "Nuget.exe encountered an error. exitcode: $lastexitcode Check logs for more information"
	}
}

Function Set-NugetConfigValue
{
	param(
		[string]$nugetPath,
		[string]$nugetConfigPath,
		[string]$name,
		[string]$value
	)

	$nugetArgList = @(
		"config","-Set",
		"$name=$value"
		"-ConfigFile", "$nugetConfigPath"
	)

	Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList
}

function Configure-Nuget
{
	param(
		[string]$nugetPath,
		[string]$nugetConfigPath,
		[string]$sourceName,
		[string]$source,
		[string]$username,
		[string]$password,
		[string]$nugetProxyUrl,
		[string]$nugetProxyUsername,
		[string]$nugetProxyPassword
	)

	#Set Source
	$nugetArgList = @(
	"sources","Add",
	"-Name","$sourceName",
	"-Source", "$source",
	"-ConfigFile", "$nugetConfigPath"
	)

	if ($username)
	{
		Write-Verbose "Setting Nuget Username to: $username"

		$nugetArgList += "-Username"
		$nugetArgList += "$username"

		if ($password)
		{
			Write-Verbose "Setting Nuget Password"

			$nugetArgList += "-Password"
			$nugetArgList += "$password"
		}
	}

	Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList

	#Set APIKey
	if ($password -and (-not $username))
	{
		Write-Verbose "Setting Nuget API Key"

		$nugetArgList = @(
			"setapikey","$password",
			"-Source", "$source",
			"-ConfigFile", "$nugetConfigPath"
			)

		Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList
	}

	#Set Proxy
	if ($nugetProxyUrl)
	{
		Write-Verbose "Seting Nuget proxy to Url= $nugetProxyUrl | User=$nugetProxyUsername"

		Set-NugetConfigValue -nugetPath "$nugetPath" -nugetConfigPath $nugetConfigPath -name "HTTP_PROXY" -value "$nugetProxyUrl"

		if ($nugetProxyUsername)
		{
			Set-NugetConfigValue -nugetPath "$nugetPath" -nugetConfigPath $nugetConfigPath -name "HTTP_PROXY.USER" -value "$nugetProxyUsername"

			if ($nugetProxyPassword)
			{
				Set-NugetConfigValue -nugetPath "$nugetPath" -nugetConfigPath $nugetConfigPath -name "HTTP_PROXY.PASSWORD" -value "$nugetProxyPassword"
			}
		}
	}
}

function Set-EBGToolVersionVariable
{
	param(
		[string]$toolName,
		[string]$version
    )

	$tool = Get-EBGToolFromConfig -toolName $toolName

	if ($version)
	{
		Write-Host "Override version for $toolName : $version"

		$variable = Get-EBGToolVersionVariable -toolName $toolName

		Write-Host "##vso[task.setvariable variable=$variable]$version"
	}
	else
	{
		Write-Host "Using default version for  $toolName : $($tool.Version)"
	}
}

function Get-EBGToolVersionVariable
{
	param(
		[string]$toolName
	)

	return "EBG_$($toolName.replace('.', '_'))_Version"
}

function Get-EBGToolFromConfig
{
	param(
		[string]$toolName
	)

	$toolsConfig = "$scriptPath\Tools.json"

	Write-Verbose "Getting $toolName details from $toolsConfig"

	$tools = ConvertFrom-Json (Get-Content -Path "$toolsConfig" -Raw)

	$tool = $tools | where Name -EQ "$toolName"

	if ($tool)
	{
		return $tool
	}
	else
	{
		throw "$toolName was was not found in $toolsConfig"
	}
}

function Get-EBGToolPath
{
	param(
		[string]$toolName,
		[string]$version
    )

	#EBG Tools
	$ebgToolsPath = $env:EBG_Tools_Path
	Write-Verbose "EBG Tools Path: $ebgToolsPath"

	if (-not $ebgToolsPath)
	{
		Write-Error "EBG_Tools_Path not found. Add 'EBG Tool Installer' before this task."
	}

	return "$ebgToolsPath\$toolName.$version"
}

function Get-EBGToolInfo
{
    param(
		[string]$toolName
    )

	$tool = Get-EBGToolFromConfig -toolName "$toolName"

	$versionVariable = Get-EBGToolVersionVariable -toolName "$toolName"

	$version = iex ('$env:' + $versionVariable)

	if ($version)
	{
		Write-Verbose "Using version provided in tool installer task: $version"

		$tool.Version = $version
	}
	else
	{
		$version = $tool.Version

		if (-not $version)
		{
			throw "Couldn't find required version for tool: $toolName"
		}

		Write-Verbose "Using default version: $version"
	}

	return $tool
}

function Get-LatestToolVersion
{
	param(
		[string]$toolName
		)

	Write-Verbose "Finding latest version for tool: $toolName"

	#EBG Tools
	$ebgToolsPath = $env:EBG_Tools_Path
	Write-Verbose "EBG Tools Path: $ebgToolsPath"

	if (-not $ebgToolsPath)
	{
		Write-Error "EBG_Tools_Path not found. Add 'EBG Tool Installer' before this task."
	}

	$tool = Get-EBGToolFromConfig -toolName $toolName

	if ($tool.Source -eq 'Nuget')
	{
		$configPath = iex ('$env:' + $nugetConfigVariable)
	}

	$nugetPath = "$ebgToolsPath\NuGet\5.9.1\nuget.exe"

	$nugetArgList = @(
		"list",
		"$toolName",
		"-ConfigFile", "$configPath",
		"-NonInteractive"
	)

	$output = Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList -returnOutput

	$toolMatches = $output | Select-String "$toolName \d+(\.\d+)+"

	if ($toolMatches)
	{
		$toolMatch = $toolMatches.Matches.Value

		$versionMatch = $toolMatch | Select-String '\d+(\.\d+)+'

		if ($versionMatch)
		{
			$version = $versionMatch.matches.Value

			Write-Host "Latest Version of $toolName is: $version"

			Write-Output $version
		}
		else
		{
			throw "Couldn't extract version. Try to specify an exact version or leave blank. $output"
		}
	}
	else
	{
		throw "Couldn't extract version. Try to specify an exact version or leave blank. $output"
	}
}

function Get-EBGTool
{
	param(
		[string]$toolName
	)

	#EBG Tools
	$ebgToolsPath = $env:EBG_Tools_Path
	Write-Verbose "EBG Tools Path: $ebgToolsPath"

	if (-not $ebgToolsPath)
	{
		Write-Error "EBG_Tools_Path not found. Add 'EBG Tool Installer' before this task."
	}

	$tool = Get-EBGToolInfo -toolName $toolName

	if ($tool.Source -eq 'Nuget')
	{
		$configPath = iex ('$env:' + $nugetConfigVariable)
	}

	Write-Host "Downloading $toolName $($tool.Version) to: $ebgToolsPath" -ForegroundColor Green

	$nugetPath = "$ebgToolsPath\NuGet\5.9.1\nuget.exe"

	$nugetArgList = @(
		"install",
		"$toolName",
		"-OutputDirectory","$ebgToolsPath",
		"-ConfigFile", "$configPath",
		"-NonInteractive"
	)

	if ($tool.Version -ne 'latest')
	{
		$nugetArgList += "-Version"
		$nugetArgList += "$($tool.Version)"
	}

	$output = Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList -returnOutput

	if ($tool.Version -eq 'latest')
	{
		$latestDir = Get-ChildItem -Path $ebgToolsPath | Where-Object {$_.Name -like "$toolName.*"} | Sort Name -Descending | Select-Object -First 1

		if ($latestDir)
		{
			$versionMatch = $latestDir | Select-String "\d+(\.\d+)+"

			if ($versionMatch)
			{
				$version = $versionMatch.matches.Value

				Write-Host "Latest Version of $toolName is: $version"

				$tool.Version = $version
			}
			else
			{
				throw "Couldn't extract version. Try to specify an exact version or leave blank."
			}

		}
		else
		{
			throw "Can't find $toolName in $ebgToolsPath. Try to specify an exact version or leave blank. $output"
		}
	}

	$toolFolder = Get-EBGToolPath -toolName $toolName -version $tool.Version

	$tool | Add-Member -MemberType NoteProperty -Name Path -Value $toolFolder

	return $tool
}

function Use-EBGTool
{
    param(
		[string]$toolName,
		[string]$version
    )

	#EBG Tools
	$ebgToolsPath = $env:EBG_Tools_Path
	Write-Verbose "EBG Tools Path: $ebgToolsPath"

	if (-not $ebgToolsPath)
	{
		Write-Error "EBG_Tools_Path not found. Add 'EBG Tool Installer' before this task."
	}

	$tool = Get-EBGToolFromConfig -toolName $toolName

	$toolFolder = Get-EBGToolPath -toolName $toolName -version $version

	if (Test-Path -Path $toolFolder)
	{
		Write-Host "$toolName $version already cached in $toolFolder"
	}
	else
	{
		if ($tool.Source -eq 'Nuget')
		{
			$configPath = iex ('$env:' + $nugetConfigVariable)
		}

		Write-Host "Downloading $toolName $version to: $ebgToolsPath" -ForegroundColor Green

		$nugetPath = "$ebgToolsPath\NuGet\5.9.1\nuget.exe"

		$nugetArgList = @(
			"install",
			"$toolName",
			"-OutputDirectory","$ebgToolsPath",
			"-ConfigFile", "$configPath",
			"-Version", "$version",
			"-NonInteractive"
		)

		Execute-Nuget -nugetPath $nugetPath -nugetArgList $nugetArgList
	}

	return $toolFolder
}

function Require-ToolsTaskVersion
{
	param(
		[int]$version
    )

	$currentVersion = $env:EBG_Tools_Task_Version

	if (-not $currentVersion)
	{
		Write-Error "EBG_Tools_Path_Version not found. Add 'EBG Tool Installer' (ver. >= 1) before this task."
	}

	$currentVersion = $currentVersion -as [int]

	if ($currentVersion -lt $version)
	{
		Write-Error "'EBG Tool Installer' version $version is required for this task version"
	}
}

function Require-ToolVersion
{
	param(
		[string]$toolName,
		[string]$version,
		[string]$minVersion
    )

	if ([System.Version]$version -lt [System.Version]$minVersion)
	{
		throw "$toolName minimum version $minVersion is required. Adjust version in 'EBG Tool Installer' task"
	}
}

Write-Verbose 'Leaving EBGToolsFunctions.ps1'