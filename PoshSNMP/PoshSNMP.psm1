Add-Type -Path $PSScriptRoot/lib/SharpSnmpLib.dll

#Dot source the files
Foreach($FolderItem in 'Private','Public') {
    $ImportItemList = Get-ChildItem -Path $PSScriptRoot\$FolderItem\*.ps1 -ErrorAction SilentlyContinue
    Foreach($ImportItem in $ImportItemList) {
        Try {
            . $ImportItem
        }
        Catch {
            throw "Failed to import function $($importItem.fullname): $_"
        }
    }
    if ($FolderItem -eq 'Public') {
        Export-ModuleMember -Function ($ImportItemList.basename | Where-Object {$PSitem -match '^\w+-\w+$'})
    }
}