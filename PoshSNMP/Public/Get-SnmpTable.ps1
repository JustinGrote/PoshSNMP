function Get-SnmpTable {
    [CmdletBinding()]
    param(
        $ComputerName,
        $Version = '2c',
        $Community = 'public',
        $ObjectIdentifier = '1.3.6.1.2.1.2.2'        
    )

    $snmpTableResult = & "$PSSCRIPTROOT\..\bin\netsnmp\snmptable.exe" -v $version -c $Community -Cf "|" -M "$PSSCRIPTROOT\..\bin\netsnmp\mibs" $ComputerName $ObjectIdentifier
    if ($snmpTableResult) {
        ConvertFrom-CSV ($snmpTableResult | select -skip 2) -Delimiter '|'
    }
    
}