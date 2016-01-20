function Invoke-SnmpWalk  {
    Param (
        #The IP or hostname of the target device. Defaults to "localhost" if not specified
	    [string]$ComputerName = "localhost",

		#SNMP community string to use to query the target device. Defaults to "public" if not specified
        [string]$Community = "public",

		#SNMP OID(s) to query on the target device. For Invoke-SnmpGet, this can be a single OID (string value) or an array of OIDs (string values)
        [Parameter(Mandatory=$True)]
	    [string[]]$ObjectIdentifier,
	
        #UDP Port to use to perform SNMP queries.
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,
		
        #Time to wait before expiring SNMP call handles.	
        [Parameter(Mandatory=$False)]
			[int]$Timeout = 3000
	)

	# $sOIDstart
	# $TimeOut is in msec, 0 or -1 for infinite

	# Create OID object
	$oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($ObjectIdentifier)

	# Create OID variable list
	if ($Host.Version.Major -le 2) {
		# PowerShell v1 and v2
		$vList = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
	} elseif ($Host.Version.Major -gt 2) {
		# PowerShell v3+
		$vList = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
	}

    #Validate the ComputerName
    $ip = try {[System.Net.Dns]::GetHostAddresses($ComputerName)[0]} catch {throw}
	
	# Create endpoint for SNMP server
	$svr = New-Object System.Net.IpEndPoint ($IPAddress, $UDPport)

	# Use SNMP v2 and walk mode WithinSubTree (as opposed to Default)
	$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
	$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

	# Perform SNMP Get
	try {
		[Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $oid, $vList, $TimeOut, $walkMode) | Out-Null
	} catch [Lextm.SharpSnmpLib.Messaging.TimeoutException] {
		Write-Host "SNMP Get on $ComputerName timed-out"
		Return $null
	} catch {
		Write-Host "SNMP Walk error: $_"
		Return $null
	}

	$res = @()
	foreach ($var in $vList) {
		$line = "" | Select OID, Data
		$line.OID = $var.Id.ToString()
		$line.Data = $var.Data.ToString()
		$res += $line
	}

	$res
}
