function Invoke-SnmpWalk  {
    Param (
		[Parameter(Mandatory=$True,Position=1)]
			[string]$TargetDevice,
			
        [Parameter(Mandatory=$true,Position=2)]
			[string]$CommunityString = "public",
			
		[Parameter(Mandatory=$True,Position=3)]
			[string]$ObjectIdentifier,
			
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,
			
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

	# Create endpoint for SNMP server
	$ip = [System.Net.IPAddress]::Parse($TargetDevice)
	$svr = New-Object System.Net.IpEndPoint ($ip, 161)

	# Use SNMP v2 and walk mode WithinSubTree (as opposed to Default)
	$ver = [Lextm.SharpSnmpLib.VersionCode]::V2
	$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree

	# Perform SNMP Get
	try {
		[Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $CommunityString, $oid, $vList, $TimeOut, $walkMode) | Out-Null
	} catch [Lextm.SharpSnmpLib.Messaging.TimeoutException] {
		Write-Host "SNMP Get on $TargetDevice timed-out"
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
