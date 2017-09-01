<#
.SYNOPSIS
    Get information on available stagers on a Empire server.
.DESCRIPTION
    Get information on available stagers on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER StagerName
    Name of the stager type to get information on. (Launcher, HTA, Launcher_Bat, 
    Launcher_VBS, PTH_WMIS, Macro, WAR, Stager, DLL, Ducky, HOP_PHP)
.EXAMPLE
    C:\PS> Get-EmpireStager -Id 0
    List all stagers and their information on the specified Empire server.
.EXAMPLE
    C:\PS> Get-EmpireStager -Id 0 -StagerName launcher
    Get information for the launcher stager on the specified Empire server.
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireStager{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        
        [ValidateSet('multi/bash','multi/launcher','multi/pyinstaller','multi/war','osx/applescript','osx/application','osx/ducky','osx/dylib','osx/jar','osx/launcher','osx/macho','osx/macro','osx/pkg','osx/safari_launcher','osx/teensy','windows/dll','windows/ducky','windows/hta','windows/launcher_bat','windows/launcher_sct','windows/launcher_vbs','windows/macro','windows/teensy')]
        [Parameter(Mandatory=$false)][string]$StagerType
        )
    Begin{if($NoSSLCheck){DisableSSLCheck}}
    Process{
        $sessionobj = Get-EmpireSession -Id $Id
        if($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            if($StagerType){$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/stagers/$($StagerType.ToLower())")}
            else{$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/stagers")}    
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            } 
        else{
            Write-Error -Message "Session not found."
            return
            }
        $stagers = Invoke-RestMethod @RequestOpts
        if($stagers) {
            $stagers.stagers | ForEach-Object -Process {
                $_.pstypenames[0] = 'Empire.Stager'
                $_
                }
            }
        }
    End{}
    }


<#
.SYNOPSIS
    Create a stager for a specified listener on a Empire server.
.DESCRIPTION
    Create a stager for a specified listener on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER StagerName
    Name of the stager type to get information on. (Launcher, HTA, Launcher_Bat, 
    Launcher_VBS, PTH_WMIS, Macro, WAR, Stager, DLL, Ducky, HOP_PHP)
.PARAMETER ListenerName
    Name of the listener to generate a stager for.
.EXAMPLE
    C:\PS> New-EmpireStager -Id 0 -ListenerName CampaingSales -StagerName launcher
    Explanation of what the example does
.NOTES
    Licensed under BSD 3-Clause license
#>
function New-EmpireStager {
    [CmdletBinding()]
    Param (
        # Session ID
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        # Listener Name
        [Parameter(Mandatory=$true)][string]$ListenerName,
        # Stager type
        [ValidateSet('osx/jar','osx/macho','osx/dylib','osx/teensy','osx/ducky','osx/macro','multi/war','windows/ducky','osx/launcher','osx/pkg','osx/application','multi/launcher','windows/launcher_bat','osx/safari_launcher','multi/pyinstaller','windows/dll','osx/applescript','windows/teensy','windows/launcher_sct','windows/hta','windows/macro','multi/bash','windows/launcher_vbs')]
        [Parameter(Mandatory=$true)][string]$StagerType,
        # File to output on remote Empire server.
        [Parameter(Mandatory=$false)][string]$OutFile,
        # Proxy to use for request (default, none, or other).
        [Parameter(Mandatory=$false)][string]$Proxy,
        # Proxy credentials ([domain\]username:password) to use for request (default, none, or other).
        [Parameter(Mandatory=$false)][string]$ProxyCreds,
        # User-agent string to use for the staging request (default, none,or other)
        [Parameter(Mandatory=$false)][string]$UserAgent,
        # Extra options hashtable 
        [Parameter(Mandatory=$false)][hashtable]$AdditionalOptions,
        # No SSl Check
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if($NoSSLCheck){DisableSSLCheck}}
    Process{
        # Prep stager options
        $stagerHash = @{StagerName=$StagerType.ToLower(); Listener=$ListenerName;}
        if ($UserAgent) {$stagerHash.Add('UserAgent', $UserAgent)}        
        if($OutFile){$stagerHash.Add('OutFile', $OutFile)}        
        if($Proxy){$stagerHash.Add('Proxy', $Proxy)}        
        if($ProxyCreds){$stagerHash.Add('ProxyCreds', $ProxyCreds)}        
        if($AdditionalOptions){$stagerHash = $stagerHash + $AdditionalOptions}
        # Convert to json
        $stagerjson = ConvertTo-Json -InputObject $stagerHash
        # Prep call
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','POST')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/stagers?token=$($sessionobj.token)")
            $RequestOpts.Add('ContentType', 'application/json')
            #$RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            $RequestOpts.Add('Body', $stagerjson)
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        # Format Response
        if($Response){
            $stagerProps = [ordered]@{}
            $ObjProperties = $Response."$($StagerType)" | Get-Member -MemberType NoteProperty
            foreach ($prop in $ObjProperties) {
                if ($prop.name -ne 'Output') {
                    $stagerProps.Add($prop.name,$Response."$($StagerType)"."$($prop.name)".Value) |Out-Null
                    } 
                else{
                    $stagerProps.Add('Output', $Response."$($StagerType)"."$($prop.name)") | Out-Null
                    }
                }
            $object = new-object psobject -Property $stagerProps
            }
        }
    End{Return $Object}
    }
