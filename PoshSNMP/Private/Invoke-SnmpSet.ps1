using namespace System.Net
using namespace Lextm.SharpSnmpLib
using namespace Lextm.SharpSnmpLib.Messaging
function Invoke-SnmpSet {
	<#
	.SYNOPSIS
	Performs an SNMPv2 SET query against the target device.
	.DESCRIPTION
	This cmdlet uses the SharpSNMP library to perform direct SNMP SET queries against the target device and OID using the provided community string.
	.EXAMPLE
	Invoke-SnmpSet -ComputerName 10.10.35.40 -Community publ1c -ObjectIdentifier 1.3.6.1.2.1.1.3.0 -OIDValue 123456 -DataType "i"
	.EXAMPLE
	Invoke-SnmpSet 10.10.35.40 publ1c 1.3.6.1.2.1.1.3.0 123456 "i"
	#>
	
	Param (
        #The IP or hostname of the target device. Defaults to "localhost" if not specified
	    [string]$ComputerName = "localhost",

		#SNMP community string to use to query the target device. Defaults to "public" if not specified
        [string]$Community = "public",

		#SNMP OID(s) to query on the target device. For Invoke-SnmpGet, this can be a single OID (string value) or an array of OIDs (string values)
        [Parameter(Mandatory=$True)]
	    [string[]]$ObjectIdentifier,
        
        #The value to set the provided OID to.
		[Parameter(Mandatory=$True,Position=4)]
			$OIDValue,
		
        <# Data type of the provided value. Valid values:
            i: INTEGER
            u: unsigned INTEGER
            t: TIMETICKS
            a: IPADDRESS
            o: OBJID
            s: STRING
            x: HEX STRING
            d: DECIMAL STRING
            n: NULL VALUE 
        #>
		[Parameter(Mandatory=$True,Position=5)]
			[ValidateSet("i","u","t","a","o","s","x","d","n")]
			[string]$DataType,
			
        #UDP Port to use to perform SNMP queries.
		[Parameter(Mandatory=$False)]
			[int]$UDPport = 161,
		
        #Time to wait before expiring SNMP call handles.	
        [Parameter(Mandatory=$False)]
			[int]$Timeout = 3000
	)

    #Validate the ComputerName
    $IPAddress = try {[Dns]::GetHostAddresses($ComputerName)[0]} catch {throw}
	
	# Create endpoint for SNMP server
	$TargetIPEndPoint = [IpEndPoint]::new($IPAddress, $UDPport)

	# Create a generic list to be the payload
	# $DataPayload = HelperCreateGenericList
	
	# Convert each OID to the proper object type and add to the list
	<# foreach ($OIDString in $ObjectIdentifiers) {
		$OIDObject = [ObjectIdentifier ($OIDString)
		$DataPayload.Add($OIDObject)
	} #>
	
	# this is where the foreach would begin
	
	$ThisOID = [ObjectIdentifier]::new($ObjectIdentifier)
	
	switch ($DataType) {
		"i" { $ThisData = [Integer32]::new([int] $OIDValue) }
		"u" { $ThisData = [Gauge32]::new([uint32] $OIDValue) }
		"t" { $ThisData = [TimeTicks]::new([uint32] $OIDValue) }
		"a" { $ThisData = [IP]::new(([IPAddress]::Parse($OIDValue))) }
		"o" { $ThisData = [ObjectIdentifier]::new($OIDValue) }
		"s" { $ThisData = [OctetString]::new($OIDValue) }
		"x" { $ThisData = [OctetString]::new([ByteTool]::Convert($OIDValue)) }
		"d" { $ThisData = [OctetString]::new([ByteTool]::ConvertDecimal($OIDValue)) } # not sure about this one actually working...
		"n" { $ThisData = [Null]::new() }
		# default { }
	}
	
	$OIDObject = [Variable]::new($ThisOID, $ThisData)
	
	# this is where the foreach would end
	
	# $DataPayload.Add($OIDObject)

	# Use SNMP v2
	$SnmpVersion = [VersionCode]::V2

	# Perform SNMP Get
	try {
		$ReturnedSet = [Messenger]::Set($SnmpVersion, $TargetIPEndPoint, $Community, $DataPayload, $Timeout)
	} catch {
	
		# can we handle this more gracefully?
		Write-Error "SNMP Set error: $_"
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
