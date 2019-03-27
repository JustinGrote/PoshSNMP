using Namespace Lextm.SharpSnmpLib
using Namespace Lextm.SharpSnmpLib.Messaging
function Invoke-SnmpWalk  {
    Param (
        #The IP or hostname of the target device. Defaults to "localhost" if not specified
	    [string]$ComputerName = "localhost",

		#SNMP community string to use to query the target device. Defaults to "public" if not specified
        [string]$Community = "public",

		#SNMP OID(s) to query on the target device. For Invoke-SnmpGet, this can be a single OID (string value) or an array of OIDs (string values)
	    [ObjectIdentifier]$ObjectIdentifier,
	
        #UDP Port to use to perform SNMP queries.
		[int]$Port = 161,

		#Which SNMP Version to use
		[VersionCode]$Version = 'V2',

		#SNMP Walk Mode
		[WalkMode]$WalkMode = 'WithinSubTree',
		
        #Time to wait before expiring SNMP call handles.	
		[int]$Timeout = 3000
	)

	$vList = [System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]]::New()

    #Validate the ComputerName
    $IPAddress = try {[System.Net.Dns]::GetHostAddresses($ComputerName)[0]} catch {throw}
	
	# Create endpoint for SNMP server
	$svr = New-Object System.Net.IpEndPoint ($IPAddress, $port)

	# Perform SNMP Get
	try {
		$numResults = [Messenger]::Walk(
			$Version, 
			$svr, 
			$Community, 
			$ObjectIdentifier, 
			$vList, 
			$TimeOut, 
			$walkMode)
		write-verbose "$numResults SNMP records returned"
	} catch [Messaging.TimeoutException] {
		write-error "SNMP Get on $ComputerName timed-out"
		Return $null
	} catch {
		write-error "SNMP Walk error: $_"
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
