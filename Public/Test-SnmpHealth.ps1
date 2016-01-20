function Test-SNMPHealth {
    <#
    .SYNOPSIS
        Performs a series of checks to ascertain the health of a remote SNMP agent
    .DESCRIPTION
        Designed as a healthtest to be used against a large list of devices. 
    .NOTES
        The MS Config Check makes the following assumptions:
        * Computer is pingable
        * Computer has remote registry enabled
        * Computer is domain joined to the same computer as is running this script
        * Currently logged in credentials have administrative rights on the Computer
    #>

    [CmdletBinding()]
    param (
        #A list of computer DNS names or IP addresses. Defaults to "localhost" if not specified.
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)][String[]]$ComputerName = "localhost",

        #SNMP Community String to test with. Defaults to "public" if not specified.
        [String]$CommunityString = "public",

        #OID to test for access. Defaults to "1.3.6.1.2.1.1.3.0" (System.SysUptime.0)
        [String]$OIDIdentifier = "1.3.6.1.2.1.1.3",

        #SNMP UDP Port. Defaults to 161
        [int]$SNMPPort = 161,

        #Check the Windows SNMP configuration as well if the SNMP tests fail. See Notes for caveats.
        [Switch]$VerifyWindowsConfig,

        #Skip the ping test. Useful if the SNMP target is behind a firewall that blocks ICMP but allows SNMP
        [Switch]$NoPing
    )

    process {
        foreach ($Computer in $ComputerName) {
            #Create Array for Test Results and initialize all test variables so that results can be displayed consistently. 
            #Not doing this can cause default Powershell Output to omit information.
            $SNMPTestResultProps = [ordered]@{}
            $SNMPTestResultProps.ComputerName = $Computer
            $SNMPTestResultProps.Ping = $null
            $SNMPTestResultProps.SNMPPortOpen = $null
            $SNMPTestResultProps.SNMPGetOID = $OIDIdentifier
            $SNMPTestResultProps.SNMPGetResult = $null
            $SNMPTestResultProps.SNMPGetValue = $null
            $SNMPTestResultProps.Registry = $null

            if (!$NoPing) {
                #Ping to see if system is online
                try {
                    $SNMPTestResultProps.Ping = test-connection $Computer -count 2 -quiet -ErrorAction stop
                    if (!$SNMPTestResultProps.Ping) {throw "Ping Test Failed"}
                }
                catch {
                    $SNMPTestResultProps.Ping = $_.Exception.Message
                    return [PSCustomObject]$SNMPTestResultProps
                }
            }

            #Check if UDP port is open. Failure of this test is not critical as it can be occasionally unreliable depending on the agent.
            try {
                $SNMPTestResultProps.SNMPPortOpen = (test-port $Computer -port $SNMPPort -UDP -ErrorAction stop).open
                if (!$SNMPTestResultProps.SNMPPortOpen) {throw "SNMP Port Test Failed"}
            }
            catch {
                $SNMPTestResultProps.SNMPPortOpen = $_.Exception.Message
            }

            #Check if we can perform an SNMP get. The default OID (sysUptime) should always be present so failing this test is considered critical.
            try {
                Invoke-SnmpGet -ComputerName
            }
            catch {

            }
            
            
            #Registry Access Test
            try {
                $ErrorActionPreference = "Stop"
                $RemoteRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$ComputerName)
                $ErrorActionPreference = "Continue"
                $SNMPTestResultProps.Registry = ($RemoteRegistry -is [Microsoft.Win32.RegistryKey])
                if (!$SNMPTestResultProps.Registry) {throw "Registry Test Failed"}
            }
            catch {
                $SNMPTestResultProps.Registry = $_.Exception.Message
                return [PSCustomObject]$SNMPTestResultProps
            }

            #Return Full results if it worked
            [PSCustomObject]$SNMPTestResultProps
        }
    }

} #Test-SNMP
#endregion
