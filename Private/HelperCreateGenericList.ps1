function HelperCreateGenericList {
	if ($Host.Version.Major -le 2) {
		# PowerShell v1 and v2
		return New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable
	} elseif ($Host.Version.Major -gt 2) {
		# PowerShell v3+
		return New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
	}$
}
