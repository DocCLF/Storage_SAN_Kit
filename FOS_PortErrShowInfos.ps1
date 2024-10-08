function FOS_PortErrShowInfos {
    <#
    .SYNOPSIS
    Displays a port error summary.

    .DESCRIPTION
    Use this command to display an error summary for a port or a range of ports. Counts are reported on frames transmitted by the port (Tx) or on frames received by the port (Rx). 
    The display contains one output line per port. Numeric values exceeding 999 are displayed in units of thousands (k), millions (m), or giga (g) if indicated.
    You can identify a single port to be configured by its port number or by its port index number in decimal or hexadecimal format. 
    Port ranges are supported with port numbers, index numbers (decimal or hexadecimal) or by specifying a slot or a slot range. 
    Use switchShow for a listing of valid ports, slots, and port index numbers. When used without operands, this command displays error summary for all ports on the switch.    

    For more information use the link below
    https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-2-x/Fabric-OS-Commands/portErrShow.html
    
    .LINK
    Brocade® Fabric OS® Command Reference Manual, 9.2.x
    https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-2-x/Fabric-OS-Commands/portErrShow.html
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        [string]$TD_RefreshView
    )
    #[Parameter(Mandatory,ValueFromPipeline)]
    #$FOS_MainInformation,
    #[Parameter(Mandatory,ValueFromPipeline)]
    #$FOS_GetUsedPorts

    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"

        Write-Debug -Message "Begin GET_PortErrShowInfos |$(Get-Date)"
        Write-Debug -Message "Counted MainInformation $($FOS_MainInformation.count) - UsedPorts: $($FOS_GetUsedPorts)"`
        <# Create a Array for the unique information of the switch used at Porterrshow #>

        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        if($TD_Device_ConnectionTyp -eq "ssh"){
            Write-Debug -Message "ssh |$(Get-Date)"
            $FOS_MainInformation = ssh $TD_Device_UserName@$TD_Device_DeviceIP "porterrshow"
        }else {
            Write-Debug -Message "plink |$(Get-Date)"
            $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "porterrshow"
        }
        <# next line one for testing #>
        #$FOS_MainInformation = Get-Content -Path "C:\Users\mailt\Documents\poerteershow2.txt"
        #Out-File -FilePath $Env:TEMP\$($TD_Line_ID)_PortErrShow_Temp.txt -InputObject $FOS_MainInformation

        $FOS_InfoCount = $FOS_MainInformation.count
        Write-Debug -Message "Number of Lines: $FOS_InfoCount "
        0..$FOS_InfoCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match '^\s+frames'){
                $FOS_advInfoTemp = $FOS_MainInformation |Select-Object -Skip $_
                $FOS_perrsh_temp = $FOS_advInfoTemp |Select-Object -Skip 2   
            }
        }
    }
    process{
        Write-Debug -Message "Start of Process from GET_PortErrShowInfos |$(Get-Date) ` "
        
        $FOS_PortErrShowfiltered = foreach ($FOS_port in $FOS_perrsh_temp){
            
            # create a var and pipe some objects in
            $FOS_PortErr = "" | Select-Object Port,frames_tx,frames_rx,enc_in,crc_err,crc_g_eof,too_short,too_long,bad_eof,enc_out,disc_c3,link_fail,loss_sync,loss_sig,f_rejected,f_busied,c3timeout_tx,c3timeout_rx,psc_err,uncor_err
            
            # select the ports
            [Int16]$FOS_PortErr.Port = (($FOS_port |Select-String -Pattern '(\d+:)' -AllMatches).Matches.Value).Trim(':')
            
            # check if the port is "active", if it is fill the objects
            #foreach($FOS_usedPortstemp in $FOS_GetUsedPorts){
                # take only used Ports in the array
               # if($FOS_PortErr.Port -eq $FOS_usedPortstemp){
                    # Number of frames transmitted (Tx).    
                    $FOS_PortErr.frames_tx = ($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[1]
                    # Number of frames received (Rx).
                    $FOS_PortErr.frames_rx = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[2])
                    # Number of encoding errors inside frames received (Rx).
                    $FOS_PortErr.enc_in = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[3])
                    # Number of frames with CRC errors received (Rx).
                    $FOS_PortErr.crc_err = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[4])
                    # Number of frames with CRC errors with good EOF received (Rx).
                    $FOS_PortErr.crc_g_eof = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[5])
                    # Number of frames shorter than minimum received (Rx).
                    $FOS_PortErr.too_short = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[6])
                    # Number of frames longer than maximum received (Rx).
                    $FOS_PortErr.too_long = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[7])
                    # Number of frames with bad end-of-frame delimiters received (Rx).
                    $FOS_PortErr.bad_eof = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[8])
                    # Number of encoding error outside of frames received (Rx).
                    $FOS_PortErr.enc_out = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[9])
                    # Number of Class 3 frames discarded (Rx).
                    $FOS_PortErr.disc_c3 = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[10])
                    # Number of link failures (LF1 or LF2 states) received (Rx).
                    $FOS_PortErr.link_fail = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[11])
                    # Number of times synchronization was lost (Rx).
                    $FOS_PortErr.loss_sync = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[12])
                    # Number of times a loss of signal was received (increments whenever an SFP is removed) (Rx).
                    $FOS_PortErr.loss_sig = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[13])
                    # Number of transmitted frames rejected with F_RJT (Tx).
                    $FOS_PortErr.f_rejected = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[14])
                    # Number of transmitted frames busied with F_BSY (Tx).
                    $FOS_PortErr.f_busied = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[15])
                    # The number of transmit class 3 frames discarded at the transmission port due to timeout (platform- and port-specific).
                    $FOS_PortErr.c3timeout_tx = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[16])
                    # The number of receive class 3 frames received at this port and discarded at the transmission port due to timeout (platform- and port-specific).
                    $FOS_PortErr.c3timeout_rx = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[17])
                    # The number of Physical Coding Sublayer (PCS) block errors. This counter records encoding violations on 10Gb/s, 16Gb/s, or 32Gb/s ports.
                    $FOS_PortErr.psc_err = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[18])
                    # The number of uncorrectable forward error corrections (FEC).
                    $FOS_PortErr.uncor_err = (($FOS_port |Select-String -Pattern '(\d+\.\d\w|\d+)' -AllMatches).Matches.Value[19])
                    # Put Line by Line into the array
                    $FOS_PortErr
                #}
            #}
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$FOS_perrsh_temp.Count) * 100)
        }
        
    }

    end {

        Close-ProgressBar -ProgressBar $ProgressBar

        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Write-Debug -Message "Start End-Block GET_PortErrShowInfos |$(Get-Date) ` "

        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                $FOS_PortErrShowfiltered | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_PortErrShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $FOS_PortErrShowfiltered | Export-Csv -Path $PSScriptRoot\Export\$($TD_Line_ID)_PortErrShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
            Write-Host "The Export can be found at $TD_Exportpath " -ForegroundColor Green
            #Invoke-Item "$TD_Exportpath\Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv"
        }else {
            <# output on the promt #>
            return $FOS_PortErrShowfiltered
        }

        return $FOS_PortErrShowfiltered

        <# Cleanup all TD* Vars #>
        #Clear-Variable FOS* -Scope Global
    }
}