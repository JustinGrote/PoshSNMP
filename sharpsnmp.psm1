#Load .NET Assemblies
$NetAssemblies = Get-Childitem -Path $PSScriptRoot\lib\*.dll -ErrorAction SilentlyContinue -Recurse
foreach ($NetAssembly in $NetAssemblies) {
	Add-Type -Path $NetAssembly.fullname -ErrorAction Stop
}

#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

#Export the public functions. This should also be done in the manifest
Export-ModuleMember -Function $Public.Basename