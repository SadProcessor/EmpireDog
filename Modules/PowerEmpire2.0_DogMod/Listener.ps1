<#
.Synopsis
   Get default Empire listener options.
.DESCRIPTION
   Get default Empire listener options.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
   C:\PS> Get-EmpireListenerOption -Id 0
   Get listener options for a Empire server.
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireListenerOption { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [ValidateSet('dbx','http','http_com','http_foreign','http_hop','http_mapi','meterpreter')]
        [Parameter(Mandatory=$true)][String]$Type,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if ($NoSSLCheck) {DisableSSLCheck}}
    Process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/options/$Type")<#-<<<--FIX#>
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            } 
        else{
            Write-Error -Message "Session not found."
            return
            }
        $response = Invoke-RestMethod @RequestOpts
        if($response){
            $PropertyNames = $response.ListenerOptions | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
            foreach ($Option in $PropertyNames){
                $optionObj = New-Object psobject
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Name' -Value $option
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Description' -Value $response.ListenerOptions.$($option).Description
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Required' -Value $response.ListenerOptions.$($option).Required
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Value' -Value $response.ListenerOptions.$($option).Value
                $optionObj.pstypenames[0] = 'Empire.Listener.Option'
                $optionObj
                }
            } 
        else{Write-Warning -Message 'No resposnse received.'}
        }
    End{}
    }

<#
.Synopsis
   Get Empire listerner information and options.
.DESCRIPTION
   Get Empire listerner information and options.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Listener name.
.EXAMPLE
   C:\PS> Get-EmpireListener -Id 0
   Get all current listeners on the Empire server.
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireListener {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
               
        [Parameter(Mandatory=$false)][string]$Name,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )

    Begin{if ($NoSSLCheck) {DisableSSLCheck}}
    Process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            if ($Name) {
                Write-Verbose -Message "Getting listerner with name $($name)."
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/$($name)")
                } 
            else {
                Write-Verbose -Message 'Getting all listeners.'
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners")
                }
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
            }
        else {
            Write-Error -Message "Session not found."
            return
            }
        #Call
        $response = Invoke-RestMethod @RequestOpts
        if($response) {$response.listeners}
        }
    End{}
    }

<#
.SYNOPSIS
    Stop and remove a specified Empire listener.
.DESCRIPTION
    Stop and remove a specified Empire listener.
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
function Remove-EmpireListener{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][int]$Id=$EmpireTarget.Session,
     
        [Parameter(Mandatory=$True)][String]$ListenerName,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if ($NoSSLCheck) {DisableSSLCheck}}
    Process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','DELETE')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/$($ListenerName)?token=$($sessionobj.token)")
            $RequestOpts.Add('ContentType', 'application/json')
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }
        #Call
        $Reply = Invoke-RestMethod @RequestOpts
        }
    End{Return $reply}
    }

<#
.Synopsis
   Create a new listener on a Empire server.
.DESCRIPTION
   Create a new listener on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
   C:\PS> New-EmpireListener -Id 1 -Name CampaingDevops -ListenerHost 192.168.1.170:443 -CertPath "/root/Desktop/Empire/data/empire.pem"
   Create an HTTPS listener by specifying a PEM certificate to use in the server on port 443.
.EXAMPLE
   C:\PS> New-EmpireListener -Id 1 -Name CampaingAgainstIT -ListenerHost 192.168.1.170 -ListenerPort 80
   Create a listener for a phishing campaing on port 80
.NOTES
    Licensed under BSD 3-Clause license
#>
function New-EmpireListener {
    [CmdletBinding(DefaultParameterSetName='Session')]
    Param(
        # Listener type (native, pivot, hop, foreign, meter).
        [ValidateSet('dbx','http','http_com','http_foreign','http_hop','http_mapi','meterpreter')]
        [Parameter(Mandatory=$true)][string]$Type,
        # Listener name.
        [Parameter(Mandatory=$True)][string]$Name,
        # Listener option hashtable.
        [Parameter(Mandatory=$false)][HashTable]$Options=@{},
        # Session ID
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        # no SSL Check            
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    Begin{if ($NoSSLCheck) {DisableSSLCheck}}
    Process{
        # create JSON for listener options
        $bodyhash = @{Name=$Name;}
        if($Options){$bodyhash+=$Options}
        $Body = ConvertTo-Json -InputObject $bodyhash
        # Get Session
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj) {
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Post')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/${type}?token=$($sessionobj.token)")<#-<<<--FIX#>
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', $Body)
            $RequestOpts
            } 
        else {
            Write-Error -Message "Session not found."
            return
            }  
        #Call
        $response = Invoke-RestMethod @RequestOpts
        if($response){$response}
        }
    End {}
    }


