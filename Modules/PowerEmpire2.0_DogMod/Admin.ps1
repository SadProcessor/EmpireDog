<#
.SYNOPSIS
    Get the version of a remote Empire headless server.
.DESCRIPTION
    Get the version of a remote Empire headless server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
    C:\PS> Get-EmpireVersion -Id 0
    Get the version for the server in the session with Id 0.
.OUTPUTS
    Empire.Version
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireVersion {
    [CmdletBinding()]
    param(
        #Session
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        #No SSL Check
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{If($NoSSLCheck){DisableSSLCheck}}
    Process{
        $sessionobj = Get-EmpireSession -Id $Id
        If($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/version")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        Else{
            Write-Error -Message "Session not found."
            return
            }
        $result = Invoke-RestMethod @RequestOpts
        If($result){
            $result.pstypenames[0] = 'Empire.Version'
            }
        }
    end{Return $result}
    }


<#
.SYNOPSIS
    Get the current Empire server config.
.DESCRIPTION
    Get the current Empire server config.
.PARAMETER Id
    Empire session Id of the session to use.
.EXAMPLE
    C:\PS> Get-EmpireConfig -Id 0
    Get config for specified session
.OUTPUTS
    Empire.Config
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireConfig{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    begin{if($NoSSLCheck){DisableSSLCheck}}
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/config")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        else{
            Write-Error -Message "Session not found."
            return
            }
        $Response = Invoke-RestMethod @RequestOpts
        if ($Response){
            $result = $Response.config
            $result.pstypenames[0] = 'Empire.Config'
            $result
            }
        }
    end{}
    }


<#
.SYNOPSIS
    Get a permanent API token for the Empire server.
.DESCRIPTION
    Get a permanent API token for the Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER UpdateSession
    Update the current session with the permanent token received from the server.
.EXAMPLE
    C:\PS> Get-EmpirePermanentToken -Id 0 -UpdateSession
    Get a permanent token and update the session used.
.OUTPUTS
    Empire.Token
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpirePermanentToken {
    [CmdletBinding(DefaultParameterSetName='Session')]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        [Parameter(Mandatory=$false)][switch]$UpdateSession
        )
    
    begin{if ($NoSSLCheck){DisableSSLCheck}}
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/admin/permanenttoken")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        else{
            Write-Error -Message "Session not found."
            return
            }
        $Response = Invoke-RestMethod @RequestOpts
        if($Response){
            $Response.pstypenames[0] = 'Empire.Token'
            $Response
            if ($UpdateSession){
                Write-Verbose -Message "Updating session with Id $($Id)."
                $toRemove = Get-EmpireSession -Id $Id
                $toUpdate = Get-EmpireSession -Id $Id
                $toUpdate.Token = $Response.token
                Remove-EmpireSession -Id $Id
                [void]$Global:EmpireSessions.add($toUpdate)
                }
            }
        }
    end{}
    }


<#
.SYNOPSIS
    Restart a Empire server.
.DESCRIPTION
    Restart a Empire server service and reloads the configuration.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
    C:\PS> Restart-EmpireServer -Id 0
.NOTES
    Licensed under BSD 3-Clause license
#>
function Restart-EmpireServer {
    [CmdletBinding(DefaultParameterSetName='Session')]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id,        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    begin{if($NoSSLCheck){DisableSSLCheck}}  
    process{
        $sessionobj = Get-EmpireSession -Id $Id
            if ($sessionobj){
                $RequestOpts = @{}
                $RequestOpts.Add('Method','Get')
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/admin/restart")
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                }
            else{
                Write-Error -Message "Session not found."
                return
                }
        $Response = Invoke-RestMethod @RequestOpts
        if($Response){$Response}
        } 
    end{}
    }



<#
.SYNOPSIS
    Shutdown the Empire server.
.DESCRIPTION
    Shutsdown the Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER RemoveSession
    Removes the session used from the current session list.
.EXAMPLE
    C:\PS> Stop-EmpireServer -Id 0 -RemoveSession
    Shutddown a remote Empire server and remove the session from the current sessions list.
.NOTES
    Licensed under BSD 3-Clause license
#>
function Stop-EmpireServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id,      
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        # Remove the session from the current session list.
        [Parameter(Mandatory=$false,ParameterSetName='Session')][switch]$RemoveSession
        )
    begin{if($NoSSLCheck){DisableSSLCheck}}
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/admin/shutdown")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        else{
            Write-Error -Message "Session not found."
            return
            }
        $Response = Invoke-RestMethod @RequestOpts
        if ($Response){
            $Response
            if($RemoveSession -and ($Response.success -eq "True")){
                Remove-EmpireSession -Id $Id
                }
            }
        }
    end {}
    }