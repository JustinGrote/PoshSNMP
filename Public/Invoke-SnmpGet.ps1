function Invoke-SnmpGet {
	<#
	.SYNOPSIS
	Performs an SNMPv2 GET query against the target device.
	.DESCRIPTION
	This cmdlet uses the SharpSNMP library to perform direct SNMP GET queries against the target device and OID using the provided community string. It is configured with sensible defaults. This will test against the local computer by default, so specify a remote host with ComputerName if you wish.
	.EXAMPLE
	Invoke-SnmpGet -ComputerName demo.snmplabs.com -Community public -ObjectIdentifier 1.3.6.1.2.1.1.3.0
	.EXAMPLE
	Invoke-SnmpGet demo.snmplabs.com public 1.3.6.1.2.1.1.3.0
    .EXAMPLE
    Invoke-SnmpGet -ObjectIdentifier 1.3.6.1.2.1.1.3.0
    Queries the system uptime on the local computer using defaults
	#>

	Param (
        #The IP or DNS Hostname of the target device. Defaults to "localhost" if not specified
	    [string]$ComputerName = "localhost",

		#Specify the SNMP version to use
		[ValidateSet('V1','V2','V3')][string]$Version = 'V1',

		#SNMP community string to use to query the target device. Defaults to "public" if not specified
        [string]$Community = 'public',

		#SNMP OID(s) to query on the target device. For Invoke-SnmpGet, this can be a single OID (string value) or an array of OIDs (string values)
	    [string[]]$ObjectIdentifier = '.1.3.6.1.2.1.1.2.0',

        #UDP Port to use to perform SNMP queries.
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,

        #Time to wait before expiring SNMP call handles.
        [Parameter(Mandatory=$False)]
			[int]$Timeout = 3000,

		#Resolve SNMP OID names using Resolve-SNMPObjectIdentifier
		[Switch]$Resolve
	)

    #Validate the ComputerName
    $IPAddress = try {[System.Net.Dns]::GetHostAddresses($ComputerName)[0]} catch {throw}

    # Create endpoint for SNMP server
	$TargetIPEndPoint = New-Object System.Net.IpEndPoint ($IPAddress, $UDPport)

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
	foreach ($OIDString in $ObjectIdentifier) {
		$OIDObject = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($OIDString)
		$DataPayload.Add($OIDObject)
	}

	# Use SNMP v2 by default
	$SnmpVersion = [Lextm.SharpSnmpLib.VersionCode]::$Version

	# Perform SNMP Get
	try {
		$ReturnedSet = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get(
			$SnmpVersion,
			$TargetIPEndPoint, 
			$Community,
			$DataPayload,
			$Timeout
		)
	} catch [Lextm.SharpSnmpLib.Messaging.TimeoutException] {
		write-error "SNMP Get on $ComputerName timed-out"
        return $null
	} catch {
		write-error "SNMP Get error: $_"
        return $null
	}

    $returnedset

	# clean up return data
	<#
    $Result = @()
	foreach ($Entry in $ReturnedSet) {
		$RecordLine = "" | Select OID, Data
		$RecordLine.OID = $Entry.Id.ToString()
		$RecordLine.Data = $Entry.Data.ToString()
		$Result += $RecordLine
	}
    #>

	#$Result
}