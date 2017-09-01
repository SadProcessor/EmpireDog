<#
.SYNOPSIS
    Get agents on a Empire server.
.DESCRIPTION
    Get all current agents on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Stale
    Get all stale agents when a name is not given.
.PARAMETER Name
    Name of agent to get.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
    C:\PS> Get-EmpireAgent -Id 0
    Get all current agents for the Empire server in the session.
.EXAMPLE
    C:\PS> Get-EmpireAgent -Id 0 -Stale
    Get all stale agents for the Empire server in the session.
.EXAMPLE
    C:\PS> Get-EmpireAgent -Id 0 -Name DC01
    Get the agent with the name DC01 for the Empire server in the session.
.OUTPUTS
    Empire.Agent
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        
        [Parameter(Mandatory=$false)][switch]$Stale,
        
        [Parameter(Mandatory=$false)][string]$Name
    )
    
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            if($Name){$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)")} 
            else {
                if($Stale){$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/stale")} 
                else{$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents")}
                }
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        else{
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        if ($Response){
            $agents = $Response.agents
            foreach($agent in $agents){
                $agent.pstypenames[0] = 'Empire.Agent'
                $agent
                }
            }
        }
    end {}
    }


<#
.SYNOPSIS
    Kills a specified Empire agent.
.DESCRIPTION
    Kills a specified Empire agent.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Name
    Name of agent to stop.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
    C:\PS> Stop-EmpireAgent -Id 0 -Name DC01
    Kills the agent named DC01
.NOTES
    Licensed under BSD 3-Clause license
#>
function Stop-EmpireAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][string]$Name,

        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )  
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process {
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','POST')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)/kill?token=$($sessionobj.token)")
            $RequestOpts.Add('ContentType', 'application/json')
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        # Call 
        $Response = Invoke-RestMethod @RequestOpts
        if ($Response) {$Response}
        }
    end {}
    }


<#
.SYNOPSIS
    Rename a Epire agent.
.DESCRIPTION
    Rename a specified agent on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Name
    Name of agent to rename.
.PARAMETER NewName
    New name for the agent.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
    C:\PS> Rename-EmpireAgent -Id 0 -Name L3RR1MCCV1DXZHH2 -NewName DC01
    Explanation of what the example does
.OUTPUTS
    Empire.Agent
.NOTES
    Licensed under BSD 3-Clause license
#>
function Rename-EmpireAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$true)][string]$Name,
        
        [Parameter(Mandatory=$true)][string]$NewName,

        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process{
        $bodyhash = @{newname=$NewName;}
        $body = ConvertTo-Json -InputObject $bodyhash
        
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','POST')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)/rename?token=$($sessionobj.token)")       
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', $body)
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        $Response
        if ($Response) {$Response}
        }
    end{}
    }


<#
.SYNOPSIS
    Register a shell command taks against one or all Empire agents.
.DESCRIPTION
    Register a shell command taks against one or all Empire agents.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Name of agent to resgiter the command task against.
.PARAMETER Command
    Windows or PowerShell command to register on a agent.
.EXAMPLE
    C:\PS> Register-EmpireAgentShellCommandTask -Id 0 -Command "get-process"
    Register the command Get-Process on all agents.
.NOTES
    Licensed under BSD 3-Clause license
#>
function Register-EmpireAgentShellCommandTask {
    [CmdletBinding()]
    [Alias('Register-EmpireCommand')]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
             
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        
        [Parameter(Mandatory=$false)][string]$Name,
        
        [Parameter(Mandatory=$false)][string]$Command
        )
    
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    
    process {
        $bodyhash = @{command=$Command}
        $body = ConvertTo-Json -InputObject $bodyhash
        
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Post')
            if($Name) {$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)/shell?token=$($sessionobj.token)")} 
            else{$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/all/shell?token=$($sessionobj.token)")}
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', $body)
            write-verbose "Body: $Body"
            } 
        else{
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        if($Response) {$Response}
        }
    end{}
    }


<#
.SYNOPSIS
    Register a module tasks against one or all Empire agents.
.DESCRIPTION
    Register a module tasks against one or all Empire agents.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Name of agent to resgiter the module task against.
.PARAMETER Module
    Full name of the module to resgiter.
.PARAMETER Options
    Hashtable with module options.
.EXAMPLE
    C:\PS> Register-EmpireAgentModuleTask  -Id 0 -Module "credentials/mimikatz/logonpasswords"
    Register module credentials/mimikatz/logonpasswords to execute against all agents.
.OUTPUTS
    Empire.Agent
.NOTES
    Licensed under BSD 3-Clause license
#>
function Register-EmpireAgentModuleTask{
    [CmdletBinding()]
    [Alias('Register-EmpireModule')]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
        
        [Parameter(Mandatory=$false)][string]$Name,
        
        [Parameter(Mandatory=$true)][string]$Module,
        
        [Parameter(Mandatory=$false)][hashtable]$Options
        )    
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process {
        if($name) {$bodyhash = @{Agent=$name}}
        else {$bodyhash = @{Agent='all'}}
        
        if ($Options) {$bodyhash += $Options}
        
        $body = ConvertTo-Json -InputObject $bodyhash
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Post')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/modules/$($module)?token=$($sessionobj.token)")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', $body)
            write-verbose "Body: $Body"
            } 
        else{
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        if ($Response){$Response}
        }
    end{}
    }

<#
.SYNOPSIS
    Get all results for scheduled taks against a Empire agent.
.DESCRIPTION
    Get all results for scheduled taks against a Empire agent. An agent can be specified by name and
    if none given it will be retrieve results for all.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Name of Empire agent.
.EXAMPLE
    C:\PS> Get-EmpireAgentTaskResult -Id 0 -Name DC01
    Get all results for agent named DC01.
.OUTPUTS
    Empire.Task.Result
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireAgentTaskResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
                
        [Parameter(Mandatory=$false)][string]$Name
        )   
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process {
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            if($Name) {$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)/results")}
            else {$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/all/results")}
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        if($Response){
            foreach ($Result in $Response.results){
                $Result.pstypenames[0] = 'Empire.Task.Result'
                $Result
                }
            }
        }
    end{}
    }


<#
.SYNOPSIS
    Clear all results for scheduled taks against a Empire agent.
.DESCRIPTION
    Clear all results for scheduled taks against a Empire agent. An agent can be specified by name and
    if none given it will be clear results for all.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Name of Empire agent.
.EXAMPLE
    C:\PS> Clear-EmpireAgentTaskResult -Id 0 -Name DC01
    Clear all results for agent named DC01.
.OUTPUTS
    Empire.Agent
.NOTES
    Licensed under BSD 3-Clause license
#>
function Clear-EmpireAgentTaskResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck,
                
        [Parameter(Mandatory=$false)][string]$Name
        )
    Begin{if ($NoSSLCheck){DisableSSLCheck}}
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Delete')
            if ($Name) {$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Name)/results?token=$($sessionobj.token)")} 
            else {$RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/all/results?token=$($sessionobj.token)")}
            $RequestOpts.Add('ContentType', 'application/json')
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        # Call
        $Response = Invoke-RestMethod @RequestOpts
        if($Response) {$Response}
        }
    end{}
    }


<#
.SYNOPSIS
    Stop and remove a specified Empire Agent.
.DESCRIPTION
    Stop and remove a specified Empire Agent.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER ListenerId
    ID number of the listener to remove.
.EXAMPLE
    C:\PS> Remove-EmpireListener -Id 0 -ListenerId 3
    Explanation of what the example does
.NOTES
    Licensed under BSD 3-Clause license
#>
function Remove-EmpireAgent{
    [CmdletBinding()]
    Param(
        # Remove All Stale
        [Parameter(Mandatory=$True,ParameterSetName='Stale')][Switch]$Stale,
        # Remove Specific Agent
        [Parameter(Mandatory=$True,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='AgentName')][String[]]$AgentName,
        # Session ID
        [Parameter(Mandatory=$false)][int]$Id=$EmpireTarget.Session,
        # No SSL Check
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if ($NoSSLCheck) {DisableSSLCheck}}
    Process{
        $reply = @()
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj){
            # If remove stale
            If($PSCmdlet.ParameterSetName -eq 'Stale'){
                # Prep
                $RequestOpts = @{}
                $RequestOpts.Add('Method','DELETE')
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/stale?token=$($sessionobj.token)")
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                #Call
                $Reply = Invoke-RestMethod @RequestOpts
                }
            <# ------------------------------------------------------------------------------------- NEED FIX
            if($PSCmdlet.ParameterSetName -eq 'AgentName'){
                Foreach($Agt in $AgentName){
                    # Kill
                    $RequestOpts = @{}
                    $RequestOpts.Add('Method','GET')   
                    $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Agt)/kill?token=$($sessionobj.token)")
                    $RequestOpts.Add('ContentType', 'application/json')
                    #$RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                    $Null = Invoke-RestMethod @RequestOpts
                    # Remove from DB
                    $RequestOpts = @{}
                    $RequestOpts.Add('Method','DELETE')                   
                    $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/agents/$($Agt)?token=$($sessionobj.token)")
                    $RequestOpts.Add('ContentType', 'application/json')
                    # Add to reply
                    $Reply += Invoke-RestMethod @RequestOpts
                    }
                }
                #>
            }
        else {
            Write-Error -Message "Session not found."
            return
            }
        }
    End{Return $reply}
    }