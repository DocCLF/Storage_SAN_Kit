function IBM_Expand_HyperswapVolume {
    <#
    .SYNOPSIS
        Expand Hyperswap-Volumes
    .DESCRIPTION
        The function queries the volumes created on the system via ssh and "lsvdisk" and saves them temporarily in an array.
        The command for extending all hyperswap volumes found is then created and returned to the console via write host.
        This command can then be copied to the console of the storage system.
        Setting options are the size in connection with the unit.
        The function does not exempt you from checking or questioning the command!
    .NOTES
        This function only supports IBM FlashStorage systems starting with version 8.3.x in a hyperswap configuration
        You can expand the size of HyperSwap volumes provided:
        - All copies of the volume are synchronized.
        - All copies of the volume are thin or compressed.
        - There are no mirrored copies.
        - The volume is not in a consistency group. To expand the volume, you must remove the active-active relationship for the volume from the remote copy consistency group. 
          The active-active relationship can be added back to the consistency group after the volume is expanded.
    .NOTES
        v1.0.1
        This function only supports IBM FlashStorage systems starting with version 8.3.x         
    .LINK
        https://www.ibm.com/docs/en/flashsystem-5x00/8.3.x?topic=commands-expandvolume
    .EXAMPLE
        IBM_Expand_HyperswapVolume -UserName superuser -DeviceIP 192.16.12.1 -expand_size 10 -unit gb

        Result: svctask expandvolume -size 10 -unit gb ExampleVolume_01    
    .EXAMPLE
        IBM_Expand_HyperswapVolume -UserName superuser -DeviceIP 192.16.12.1 -FilterName Volu -expand_size 128849018880 -unit b

        Result: svctask expandvolume -size 128849018880 -unit b VolumeName_01     
    .EXAMPLE
        IBM_Expand_HyperswapVolume -UserName superuser -DeviceIP 192.16.12.1 -FilterName *Volu*

        Result: VolumeName_01
                11-VolName_01
                VolumeName_02   
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$UserName,
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$DeviceIP,
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$FilterName,
        [Parameter(ValueFromPipeline)]
        [Int64]$expand_size = 0,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("b","kb","mb","gb","tb","pb")]
        [string]$unit,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_export = "no"
    )
    <# suppresses error messages #>
    $ErrorActionPreference="SilentlyContinue"
    <# count to split into 10-liner #>
    [Int16]$i=0
    $TD_CollectVolInfo = ssh $UserName@$DeviceIP "lsvdisk -delim :"
    Start-Sleep -Seconds 3
    foreach($TD_info in $TD_CollectVolInfo) {
        $TD_Vol_Info = ($TD_info | Select-String -Pattern '^\d+:([a-zA-Z0-9_-]*)' -AllMatches).Matches.Groups.Value[1]
        Write-Debug -Message $TD_Vol_Info
        if($TD_Vol_Info -like "$($FilterName)"){
            <# To prevent duplicate entries #>
            if($TD_Temp -eq $TD_Vol_Info){break}
            <# Returns the command for the cli only if expand size is set #>
            if($expand_size -gt 0) {
                if($unit -eq ""){Write-Host "If a expand size is specified, we also need a size specification of a unit such as kb,mb,gb,tb, etc.!" -ForegroundColor Red; Start-Sleep -Seconds 5; exit}
                Write-Host "svctask expandvolume -size $expand_size -unit $unit $TD_Vol_Info"
                <# export *txt without line split #>
                if($TD_export -eq "yes"){"svctask expandvolume -size $expand_size -unit $unit $TD_Vol_Info " | Out-File -FilePath .\Expand_HYPSWP_Volume.txt -Append}
            }else {
                Write-host $TD_Vol_Info
            }
            <# split with 2 line of nothing and reset i #>
            $i++
            if($i -eq 10){Write-Host "`n `n"; $i = 0}
        }
        <# Copy the current value to the temp value for the duplicate check #>
        $TD_Temp = $TD_Vol_Info
    }
    Write-Host "`n#Use the expandvolume command ONLY to expand the size of a HyperSwap® volume by a specified capacity.`n" -ForegroundColor Yellow
    Write-Host "`n#And last but not least, if you are not sure then please: 'Read the manual'! ;) " -ForegroundColor Red
    <# Tidying up for the conscience #>
    Clear-Variable TD* -Scope Global;
}