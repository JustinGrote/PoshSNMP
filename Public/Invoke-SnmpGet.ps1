function Invoke-SnmpGet {
	<#
	.SYNOPSIS
	Performs an SNMP GET query against the target device.
	.DESCRIPTION
	This cmdlet uses the SharpSNMP library to perform direct SNMP GET queries against the target device and OID using the provided community string.
	.EXAMPLE
	Invoke-SnmpGet 10.10.35.40 publ1c 1.3.6.1.2.1.1.3.0
	.PARAMETER TargetDevice
	The IP or hostname of the target device.
	.PARAMETER CommunityString
	SNMP community string to use to query the target device.
	.PARAMETER ObjectIdentifiers
	SNMP OID(s) to query on the target device. For Invoke-SnmpGet, this can be a single OID (string value) or an array of OIDs (string values).
	.PARAMETER UDPport
	UDP Port to use to perform SNMP queries.
	.PARAMETER Timeout
	Time to wait before expiring SNMP call handles.
	#>
	
	Param (
		[Parameter(Mandatory=$True,Position=1)]
			[string]$TargetDevice,
			
        [Parameter(Mandatory=$true,Position=2)]
			[string]$CommunityString = "public",
			
		[Parameter(Mandatory=$True,Position=3)]
			$ObjectIdentifiers,
			
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,
			
        [Parameter(Mandatory=$False)]
			[int]$Timeout = 3000
	)
		
	# Create endpoint for SNMP server
	$TargetIPEndPoint = New-Object System.Net.IpEndPoint ($(HelperValidateOrResolveIP $TargetDevice), $UDPport)

	# Create a generic list to be the payload
	if ($Host.Version.Major -le 2) {
		# PowerShell v1 and v2
		$DataPayload = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
	} elseif ($Host.Version.Major -gt 2) {
		# PowerShell v3+
		$DataPayload = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
	}
	
	#$DataPayload = HelperCreateGenericList
	# WHY DOESN'T THIS WORK?! this should replace the lines above; what is different?
	
	# Convert each OID to the proper object type and add to the list
	foreach ($OIDString in $ObjectIdentifiers) {
		$OIDObject = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($OIDString)
		$DataPayload.Add($OIDObject)
	}

	# Use SNMP v2
	$SnmpVersion = [Lextm.SharpSnmpLib.VersionCode]::V2

	# Perform SNMP Get
	try {
		$ReturnedSet = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($SnmpVersion, $TargetIPEndPoint, $CommunityString, $DataPayload, $Timeout)
	} catch [Lextm.SharpSnmpLib.Messaging.TimeoutException] {
		throw "SNMP Get on $TargetDevice timed-out"
	} catch {
		throw "SNMP Get error: $_"
	}

	# clean up return data
	$Result = @()
	foreach ($Entry in $ReturnedSet) {
		$RecordLine = "" | Select OID, Data
		$RecordLine.OID = $Entry.Id.ToString()
		$RecordLine.Data = $Entry.Data.ToString()
		$Result += $RecordLine
	}

	$Result
}