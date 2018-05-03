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
                #The write-progress in invoke-webrequest slows it down significantly
                $progressPreference = "silentlycontinue"
                $result = (invoke-webrequest @iwrParams -uri "$oidinfouri/$OIDItem").content -replace '\n'
                $progressPreference = "continue"
                $oidScrapeResult = $oidDescriptionRegex.match($result)
                if ($oidScrapeResult.success) {
                    $newOIDResult = ($oidScrapeResult.groups | where name -eq oidname).value
                } else {
                    write-error "Unable to resolve the OID $OIDItem, either it doesn't exist, oid-info changed its site format, or oid-info is not visible"
                }
            }
            
            if ($newOIDResult) {
                [Switch]$SCRIPT:newOIDsFound = $true
                $OIDCache."$OIDItem" = $newOIDResult
                return $newOIDResult
            }
        }}

        end {
            if ($newOIDsFound) {
                export-clixml -inputobject $OIDCache -path $CacheFilePath
            }
        }
    }