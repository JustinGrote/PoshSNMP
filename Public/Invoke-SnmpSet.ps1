function Invoke-SnmpSet {
	<#
	.SYNOPSIS
	Performs an SNMP SET query against the target device.
	.DESCRIPTION
	This cmdlet uses the SharpSNMP library to perform direct SNMP SET queries against the target device and OID using the provided community string.
	.EXAMPLE
	Invoke-SnmpSet 10.10.35.40 publ1c 1.3.6.1.2.1.1.3.0 123456 "i"
	.EXAMPLE
	Invoke-SnmpSet -TargetDevice 10.10.35.40 -CommunityString publ1c -ObjectIdentifier 1.3.6.1.2.1.1.3.0 -OIDValue 123456 -DataType "i"
	.PARAMETER TargetDevice
	The IP or hostname of the target device.
	.PARAMETER CommunityString
	SNMP community string to use to query the target device.
	.PARAMETER ObjectIdentifier
	SNMP OID to query on the target device. For Invoke-SnmpSet, this can only be a single OID (string value). Until I maybe fix it someday
	.PARAMETER OIDValue
	The value to set the provided OID to.
	.PARAMETER DataType
	Data type of the provided value. Valid values:
		i: INTEGER
		u: unsigned INTEGER
		t: TIMETICKS
		a: IPADDRESS
		o: OBJID
		s: STRING
		x: HEX STRING
		d: DECIMAL STRING
		n: NULL VALUE
	.PARAMETER UDPport
	UDP Port to use to perform SNMP queries.
	.PARAMETER Timeout
	Time in milliseconds to wait before expiring SNMP call handles. For unlimited timeout, provide 0 or -1.
	#>
	
	Param (
		[Parameter(Mandatory=$True,Position=1)]
			[string]$TargetDevice,
			
        [Parameter(Mandatory=$true,Position=2)]
			[string]$CommunityString = "public",
			
		[Parameter(Mandatory=$True,Position=3)]
			[string]$ObjectIdentifier,
			
		[Parameter(Mandatory=$True,Position=4)]
			$OIDValue,
			
		[Parameter(Mandatory=$True,Position=5)]
			[ValidateSet("i","u","t","a","o","s","x","d","n")]
			[string]$DataType,
			
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,
			
        [Parameter(Mandatory=$False)]
			[int]$Timeout = 3000
	)


	if (![Reflection.Assembly]::LoadWithPartialName("SharpSnmpLib")) {
		Write-Error "Missing Lextm.SharpSnmpLib Assembly; is it installed?"
		return
	}
	
	# Create endpoint for SNMP server
	$TargetIPEndPoint = New-Object System.Net.IpEndPoint ($(HelperValidateOrResolveIP $TargetDevice), $UDPport)

	# Create a generic list to be the payload
	$DataPayload = HelperCreateGenericList
	
	# Convert each OID to the proper object type and add to the list
	<# foreach ($OIDString in $ObjectIdentifiers) {
		$OIDObject = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($OIDString)
		$DataPayload.Add($OIDObject)
	} #>
	
	# this is where the foreach would begin
	
	$ThisOID = New-Object Lextm.SharpSnmpLib.ObjectIdentifier $ObjectIdentifier
	
	switch ($DataType) {
		"i" { $ThisData = New-Object Lextm.SharpSnmpLib.Integer32 ([int] $OIDValue) }
		"u" { $ThisData = New-Object Lextm.SharpSnmpLib.Gauge32	 ([uint32] $OIDValue) }
		"t" { $ThisData = New-Object Lextm.SharpSnmpLib.TimeTicks ([uint32] $OIDValue) }
		"a" { $ThisData = New-Object Lextm.SharpSnmpLib.IP ([Net.IPAddress]::Parse($OIDValue)) }
		"o" { $ThisData = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($OIDValue) }
		"s" { $ThisData = New-Object Lextm.SharpSnmpLib.OctetString ($OIDValue) }
		"x" { $ThisData = New-Object Lextm.SharpSnmpLib.OctetString ([Lextm.SharpSnmpLib.ByteTool]::Convert($OIDValue)) }
		"d" { $ThisData = New-Object Lextm.SharpSnmpLib.OctetString ([Lextm.SharpSnmpLib.ByteTool]::ConvertDecimal($OIDValue)) } # not sure about this one actually working...
		"n" { $ThisData = New-Object Lextm.SharpSnmpLib.Null }
		# default { }
	}
	
	$OIDObject = New-Object Lextm.SharpSnmpLib.Variable ($ThisOID, $ThisData)
	
	# this is where the foreach would end
	
	$DataPayload.Add($OIDObject)
	

	# Use SNMP v2
	$SnmpVersion = [Lextm.SharpSnmpLib.VersionCode]::V2

	# Perform SNMP Get
	try {
		$ReturnedSet = [Lextm.SharpSnmpLib.Messaging.Messenger]::Set($SnmpVersion, $TargetIPEndPoint, $CommunityString, $DataPayload, $Timeout)
	} catch {
	
		# can we handle this more gracefully?
		Write-Host "SNMP Set error: $_"
		Return $null
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
