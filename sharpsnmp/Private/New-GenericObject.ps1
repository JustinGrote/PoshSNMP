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