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