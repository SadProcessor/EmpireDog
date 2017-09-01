<#
.SYNOPSIS
    Get information on Empire modules.
.DESCRIPTION
    Get information on Empire modules.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER ModuleName
    Specific name of module to get information on.
.PARAMETER Category
    Module category to enumerate.
.EXAMPLE
    C:\PS> Get-EmpireModule -Id 0 -Category Code_Execution
    Get all modules under the code execution category.
.EXAMPLE
    C:\PS> Get-EmpireModule -Id 0 -Category Code_Execution | Select-Object -Property name
    Get all modules names only under the code execution category.
.EXAMPLE
    C:\PS> Get-EmpireModule -Id 0 
    Get all modules available.
.EXAMPLE
    C:\PS> Get-EmpireModule -Id 0 -ModuleName code_execution/invoke_shellcode
    Get specific information on the module
.NOTES
    Licensed under BSD 3-Clause license
#>
function Get-EmpireModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$ModuleName,
        
        [ValidateSet('TrollSploit,Situational_Awareness','Recon','Privesc',
                      'Persistence','Management','Lateral_Movement','Exploitation',
                      'Exfiltration','Credentials','Collection','Code_Execution')]
        [Parameter(Mandatory=$false)][string]$Category,
        
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
            
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    
    begin{if($NoSSLCheck){DisableSSLCheck}}
    
    process{
        $sessionobj = Get-EmpireSession -Id $Id
        if ($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Get')
            if($ModuleName) {
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/modules/$($ModuleName)")
                }
            else {
                $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/modules")
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
        # Format Response
        if($Response){
            if($Category.length -gt 0){
                $Response.modules | ForEach-Object -Process{
                    if($_.name -match $Category.ToLower()){
                        $_.pstypenames[0] = 'Empire.Module'
                        $_
                        }
                    } 
                } 
            else {
                $Response.modules | ForEach-Object -Process {
                    $_.pstypenames[0] = 'Empire.Module'
                    $_
                    }
                }
            }
        }
    end{}
    }


<#
.SYNOPSIS
    Search modules for a specific term on a Empire server.
.DESCRIPTION
    Search modules for a specific term.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER SearchTerm
    Text to search for.
.PARAMETER Field
    Module field to search on, if not specified it will search all fields.
.EXAMPLE
    C:\PS> Search-EmpireModule -Id 0 -SearchTerm 'password' -Field Comment
    Search for modules with the word password in the comment.
.EXAMPLE
    C:\PS> Search-EmpireModule -Id 0 -SearchTerm 'darkoperator' -Field Author
    Search for modules where the author is DarkOperator.
.EXAMPLE
    C:\PS> Search-EmpireModule -Id 0 -SearchTerm 'mimikatz' -Field Name | Select-Object -Property name
    Get only the names of modules with the word mimikatz in the name.
.OUTPUTS
    Empire.Module
.NOTES
    Licensed under BSD 3-Clause license
#>
function Search-EmpireModule{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][ValidateSet('Comment', 'Description', 'Name', 'Author')][string]$Field,
        
        [Parameter(Mandatory=$true)][string]$SearchTerm,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)][Int]$Id=$EmpireTarget.Session,
        
        [Parameter(Mandatory=$false)][switch]$NoSSLCheck
        )
    
    begin{if($NoSSLCheck){DisableSSLCheck}}
    process{
        switch ($Field){
            'Comment' {$URIPath = '/api/modules/search/comments'}
            'Name'{$URIPath = '/api/modules/search/modulename'}
            'Author' {$URIPath = '/api/modules/search/author'}
            'Description' {$URIPath = '/api/modules/search/description'}
            Default{$URIPath = '/api/modules/search'}
            }
        
        $BodyHash = @{term=$SearchTerm}
        $BodyJson = ConvertTo-Json -inputobject $BodyHash
        
        $sessionobj = Get-EmpireSession -Id $Id
        if($sessionobj){
            $RequestOpts = @{}
            $RequestOpts.Add('Method','Post')
            $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)$($URIPath)?token=$($sessionobj.Token)")
            $RequestOpts.Add('ContentType', 'application/json')
            $RequestOpts.Add('Body', $BodyJson)
            } 
        else{
            Write-Error -Message "Session not found."
            return
            }
        
        $response = Invoke-RestMethod @RequestOpts
        if($response){
            $response.modules | ForEach-Object -Process {
                $_.pstypenames[0] = 'Empire.Module'
                $_
                }
            } 
        }
    end{}
    }