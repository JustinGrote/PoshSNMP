
function Install-Assembly {
	<#
	.SYNOPSIS
	Installs a managed assembly to the .Net GAC.
	.DESCRIPTION
	This cmdlet installs a .Net managed assembly into the .Net Global Assembly Cache. Please note that this cmdlet requires elevation.
	.EXAMPLE
	Install-Assembly .\myassembly\bin\myassembly.dll
	.PARAMETER Path
	Path to the assembly that you would like to install.
	#>
	
	Param (
		[Parameter(Mandatory=$True,Position=1)]
			[string]$Path
	)
		
	[Reflection.Assembly]::Load("System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
	$publish = New-Object System.EnterpriseServices.Internal.Publish
	$InstallToGac = $publish.GacInstall( (Resolve-Path $Path).Path )
	
	# todo: how to confirm success?
}



function New-GenericObject {
	# Creates an object of a generic type - see http://www.leeholmes.com/blog/2006/08/18/creating-generic-types-in-powershell/
	# this is only used for powershell v2 and earlier

	param(
		[string] $typeName = $(throw "Please specify a generic type name"),
		[string[]] $typeParameters = $(throw "Please specify the type parameters"),
		[object[]] $constructorParameters
	)

	## Create the generic type name
	$genericTypeName = $typeName + '`' + $typeParameters.Count
	$genericType = [Type] $genericTypeName

	if(-not $genericType) {
		throw "Could not find generic type $genericTypeName"
	}

	## Bind the type arguments to it
	[type[]] $typedParameters = $typeParameters
	$closedType = $genericType.MakeGenericType($typedParameters)
	if(-not $closedType) {
		throw "Could not make closed type $genericType"
	}

	## Create the closed version of the generic type
	,[Activator]::CreateInstance($closedType, $constructorParameters)
}



function HelperCreateGenericList {
	if ($Host.Version.Major -le 2) {
		# PowerShell v1 and v2
		return New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
	} elseif ($Host.Version.Major -gt 2) {
		# PowerShell v3+
		return New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
	}$
}



function HelperValidateOrResolveIP ($TargetIP) {
	$ParsedIP = [Net.IPAddress]::Parse("0.0.0.0")
	try {
		[Net.IPAddress]::TryParse([Net.IPAddress]::Parse($TargetIP),[ref]$ParsedIP) | Out-Null
		
		# if this runs, the target IP here is valid; turn it into an object
		$TargetIP = $ParsedIP
	} catch {
		# if it errors and fires this catch, we need to try to resolve the name
		$ParsedIP = @([Net.Dns]::GetHostEntry($TargetIP))[0].AddressList[0]
	}
	
	$ParsedIP
}