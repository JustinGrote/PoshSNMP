function Resolve-SnmpObjectIdentifier {
    <#
    .SYNOPSIS
    Retrieves the resolved name of an SNMP OID via some very poor screenscraping from oid-info.com
    .NOTES
    Has a caching mechanism to prevent re-querying already identified results
    #>
        [Cmdletbinding()]
        param (
            #The SNMP OID to query the name for
            [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
                [String[]]$objectIdentifier = '.1.3.6.1.2.1.1.2',
            #Do not use local cache and force query for the entry
            [Switch]$NoCache,
            #The path to the cache CLIXML file. Defaults to temp folder
            $CacheFilePath = (join-path $env:temp "ResolveSNMPObjectIdentifierCache.clixml")
        )
        begin {
            [uri]$oidinfouri = 'http://www.oid-info.com/get'
            [regex]$oidParentRegex = '(?<oidparent>.*)(?<oidchild>\.\d+?)$'
            [regex]$oidDescriptionRegex = '<strong><code>(?<oidname>\w+?)\((?<oidnum>\d+?)\)</code></strong>'
            if (test-path $CacheFilePath) {
                $OIDCache = import-clixml $CacheFilePath
            } else {
                $OIDCache = @{}
            }
        }

        process { foreach ($OIDItem in $objectIdentifier) {
            #Strip any leading dot notation
            $OIDItem = $OIDItem -replace '^\.',''

            #Determine the OID parent
            $oidParentregexResult = $oidparentregex.match($oidItem)
            $oidParent = $oidParentregexResult.groups["oidparent"]
            $oidChild = $oidParentregexResult.groups["oidchild"]

            $iwrParams = @{
                #Appear to be google chrome browser
                UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.117 Safari/537.36'
                UseBasicParsing = $true
            }

            #Check cache
            $OIDCachedResult = $OIDCache."$oidItem"
            if ($OIDCachedResult) {
                return $OIDCachedResult
            } else {
                #try the OID parent if not found
                $oidCachedResult = $oidCache."$oidParent"
                if ($oidCache."$oidParent") {
                    write-verbose "Could not find $oidItem but found its parent OID."
                    return ($oidCachedResult + $oidchild)
                }
            } 
            
            write-verbose "$oidItem or its parent not found in cache. Checking oid-info.com"
            #The write-progress in invoke-webrequest slows it down significantly
            $progressPreference = "silentlycontinue"
            #Invoke-webrequest doesn't throw a terminating error even if you set erroraction stop
            $erroractionpreference = "stop"
            try {
                $result = (invoke-webrequest @iwrParams -uri "$oidinfouri/$OIDItem" -erroraction stop).content -replace '\n'
            } catch {
                #Try the parent OID if its not available
                try {
                    $result = (invoke-webrequest @iwrParams -uri "$oidinfouri/$OIDParent" -erroraction stop).content -replace '\n'
                } catch {write-verbose "OID parent not found either"}
                
                if ($result) {
                    [switch]$OIDParentUsed = $true
                } else {
                    write-error "Unable to resolve the OID $OIDItem, either it doesn't exist, oid-info changed its site format, or oid-info is not visible"
                    continue
                }
            }
            
            $progressPreference = "continue"
            $erroractionpreference = "continue"
            $oidScrapeResult = $oidDescriptionRegex.match($result)
            $oidScrapeNameValue = $oidScrapeResult.groups["oidname"].value
            if ($oidScrapeResult.success -and $oidScrapeNameValue) {
                $newOIDResult = $oidScrapeNameValue
            } else {
                write-error "Couldn't analyze $OIDItem on oid-info.com. Maybe they changed their site format?"
                continue
            }
            
            if ($newOIDResult) {
                [Switch]$SCRIPT:newOIDsFound = $true
                
                if ($OIDParentUsed) {
                    $OIDCache."$OIDParent" = $newOIDResult
                    return ($newOIDResult + $oidChild)
                } else {
                    $OIDCache."$OIDItem" = $newOIDResult
                    return $newOIDResult
                }
            }
        }}

        end {
            if ($newOIDsFound) {
                export-clixml -inputobject $OIDCache -path $CacheFilePath
            }
        }
    }