# Invoke-CypherStuff

################################################################################## Node

<#
.Synopsis
   Retrieve Bloodhound Node Data
.DESCRIPTION
   Query BloodHound API to retrieve Node Data
   Specify Node type and Target Name
   Also used to refresh Node Lists
.EXAMPLE
   Node -User Bob
   Returns Data for Node named 'Bob'
   use -Raw for full data
.EXAMPLE
   Node -Refresh
   Retrieve/Refresh all Node Lists
.INPUTS
   Target Node(s) if not -refresh
   Accepts Pipeline Input
.OUTPUTS
   Node Info
.NOTES
   Accepts Target Name over pipeline
   Accepts Multiple Input
.COMPONENT
   This cmdlet belongs to CypherDog.psm1
.ROLE
   This cmdlet belongs to CypherDog.psm1
.FUNCTIONALITY
   Query BloodHound API to retrieve Node Information
   (+ Refresh Node Lists)
#>
function Invoke-CypherNode{
    [CmdletBinding()]
    [Alias('Node')]
    Param(
        # Get User Node
        [Parameter(Mandatory=$true,ParameterSetName='User')][Switch]$User,
        # Get Group Node
        [Parameter(Mandatory=$true,ParameterSetName='Group')][Switch]$Group,
        # Get Computer Node
        [Parameter(Mandatory=$true,ParameterSetName='Computer')][Switch]$Computer,
        # Refresh Node Lists
        [Parameter(Mandatory=$true,ParameterSetName='Refresh')][Switch]$Refresh
        )
    DynamicParam{
        # Select Matching Node List
        Switch($PSCmdlet.ParameterSetName){
            'User'{$NodeList=$Global:CypherDog.User}
            'Group'{$NodeList=$Global:CypherDog.Group}
            'Computer'{$NodeList=$Global:CypherDog.Computer}
            'Refresh'{}
            }
        if($PSCmdlet.ParameterSetName -ne 'Refresh'){
            ## Dictionary
            # Create runtime Dictionary for this ParameterSet
            $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
            ## From 
            # Create Attribute Object
            $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib1.Mandatory = $true
            $Attrib1.Position = 1
            $Attrib1.ValueFromPipeline=$true
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

            ## Return Raw Object
            # Create Attribute Object
            $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib0.Mandatory = $false
            # Create AttributeCollection object for the attribute Object
            $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute
            $Collection0.Add($Attrib0)
            # Create Runtime Parameter with matching attribute collection
            $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Raw', [Switch], $Collection0)
            # Add Runtime Param to dictionary
		    $Dictionary.Add('Raw',$dynParam0)

		    #return Dictionary
		    return $Dictionary
            }
        }
    Begin{
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        Write-verbose $Addr
        # Prep Query
        $Query = "MATCH (A:$($PSCmdlet.ParameterSetName) {name: {ParamA}}) RETURN A" 
        $Result = @()     
        }
	Process{
        If($PSCmdlet.ParameterSetName -eq 'Refresh'){
            #For Each Item
            'User','Group','Computer','Domain' |%{
                #Prep Query
                $Body = "{`"query`":`"MATCH (X:$_) RETURN X`"}"
                Write-Verbose $Body
                #Query BloodHound DB
                Try{$Results = Invoke-restmethod -Uri $addr -Method Post -Headers $header -body $Body}Catch{$Error[0].Exception}
                # Set DBDog Prop
                $Global:CypherDog.$_ = $Results.data.data.name | sort -Unique
                }
            $Result =  $Global:CypherDog
            Return $Result       
            }
        Else{
            Foreach($Target in $DynParam1.Value){
                $Body = "{`"query`" : `"$Query`",`"params`" : { `"ParamA`" : `"$Target`" }}" 
                Write-verbose $Body
                # Try Call
		        $Result += Try{Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
		        }
            }
        }
	End{
        # Return Result
		if($DynParam0.value -eq $true){Return $Result.data}
        else{Return $Result.data.data}
		}
	}


############################################################################ NodeSearch

<#
.Synopsis
   Search Bloodhound Nodes
.DESCRIPTION
   Query BloodHound API to retrieve Node Name by PartialName | PropertyName | PorpertyName&Value
   Specify Node type and match pattern
   or Specify property name and optional value
.EXAMPLE
   NodeSearch -Group -Match 'Admin'
   Return all Group Nodes matching term 'Admin'
.EXAMPLE
   NodeSearch -Computer Secret
   Returns all Computer Nodes matching term 'Secret'
.INPUTS
   Search Items 
.OUTPUTS
   Matching Node name
.NOTES
   Accepts regex
   Matches against CypherDog object for name match (No call to API)
.COMPONENT
   This cmdlet belongs to CypherDog.ps1
.ROLE
   Helper Search Funtion
.FUNCTIONALITY
   Search Node names by partial name or by property (& optional value)
#>
function Invoke-CypherNodeSearch{
    [CmdletBinding()]
    [Alias('NodeSearch')]
    Param(
        
        # Search Category User
        [Parameter(Mandatory=$True,ParameterSetName='SearchUser')]
        [Parameter(Mandatory=$True,ParameterSetName='SearchUserProperty')][Switch]$User,
        # Search Category User
        [Parameter(Mandatory=$True,ParameterSetName='SearchGroup')]
        [Parameter(Mandatory=$True,ParameterSetName='SearchGroupProperty')][Switch]$Group,
        # Search Category User
        [Parameter(Mandatory=$True,ParameterSetName='SearchComputer')]
        [Parameter(Mandatory=$True,ParameterSetName='SearchComputerProperty')][Switch]$Computer,
        
        # Specify Match 
        [Parameter(Position=0,Mandatory=$True,ParameterSetName='SearchUser')]
        [Parameter(Position=0,Mandatory=$True,ParameterSetName='SearchGroup')]
        [Parameter(Position=0,Mandatory=$True,ParameterSetName='SearchComputer')][String]$Match,
        
        # Specify Property Name
        [Parameter(Mandatory=$True,ParameterSetName='SearchUserProperty')]
        [Parameter(Mandatory=$True,ParameterSetName='SearchGroupProperty')]
        [Parameter(Mandatory=$True,ParameterSetName='SearchComputerProperty')][String]$Property,

        # Specify Property Value
        [Parameter(Mandatory=$False,ParameterSetName='SearchUserProperty')]
        [Parameter(Mandatory=$False,ParameterSetName='SearchGroupProperty')]
        [Parameter(Mandatory=$False,ParameterSetName='SearchComputerProperty')][String]$Value
        )
    Begin{
		# Set Address and Headers (Only used for property checks - Node name are match against $CypherDog obj)
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}

        # Select list for Name Search in chosen category
        Switch($PSCmdlet.ParameterSetName){
            'SearchUser'         {$List=$Global:CypherDog.User}
            'SearchGroup'        {$List=$Global:CypherDog.Group}
            'SearchComputer'     {$List=$Global:CypherDog.Computer}
            }
        
        # Get Nodetype for Node Property DB query
        If($User){$NodeType='User'}
        ElseIf($Group){$NodeType='Group'}
        ElseIf($Computer){$NodeType='Computer'}
        }
    Process{
        # If search for Property
        if($PSCmdlet.ParameterSetName -match 'Property$'){
            Write-Verbose $Addr
            #If search for value
            if($Value){
                # Replace escape backslash if any
                $Value = $Value.Replace('\','\\')
                $Query = "MATCH (n:$NodeType) WHERE n.$Property={Value} RETURN n"
                $Body = "{`"query`" : `"$Query`",`"params`" : { `"Value`" : `"$Value`" }}"
                }
            #If search for prop only
            Else{
                $Query= "MATCH (n:$NodeType) WHERE exists(n.$Property) RETURN n"
                $Body="{`"query`" : `"$Query`"}"
                }
            Write-Verbose $Body
            # Make Call
            $Result = Try{Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
            If($Result.data){$Result = $Result.data.data.name}
            Else{$Result=$Null}
            }
        
        # If name Search
        Else{$Result = $List -Match $Match}
        }
    End{
        # Return Results
        Return $Result 
        }
    }


############################################################################ NodeUpdate

<#
.Synopsis
   Add/update/remove Node Property
.DESCRIPTION
   Add Custom Property to Bloodhound Node
   Specify Node Name(s), Property name, property value
   Also used to remove properties with -remove
.EXAMPLE
   NodeUpdate -Node ACHAVARIN@EXTERNAL.LOCAL -Property MyProp -Value MyVal
   Create/Update Property MyProp with value MyVal
.EXAMPLE
   'ACHAVARIN@EXTERNAL.LOCAL' | NodeUpdate -Prop MyProp -Val MyVal
   Same as previous example over pipeline (accepts list)
.EXAMPLE
    NodeUpdate ACHAVARIN@EXTERNAL.LOCAL -Prop MyProp -Remove
    Remove property MyProp
.INPUTS
   Node(s)/Property/Value
.OUTPUTS
   None if success
.NOTES
   Accepts Multiple Nodes
   Accepts Pipeline input
.COMPONENT
   This cmdlet belongs to CypherDog.psm1
.ROLE
   This cmdlet belongs to CypherDog.psm1
.FUNCTIONALITY
   Add Custom property and value to specified node(s)
#>
Function Invoke-CypherNodeUpdate{
    [Alias('NodeUpdate')]
    Param(
        [Parameter(Mandatory=$true,Position=0,ValuefromPipeline=$true)][String[]]$Node,
        [Parameter(Mandatory=$true)][String]$Property,
        [Parameter(Mandatory=$true,ParameterSetname='Update')][String]$Value,
        [Parameter(Mandatory=$true,ParameterSetname='Remove')][Switch]$Remove
        )
    Begin{
        # Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header = @{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        Write-verbose $Addr
        # Init Results
        $Result = @()
        # Replace escape backslash if any
        $Value = $Value.Replace('\','\\')
        }
    Process{
        Foreach($Target in $Node){
            # Prep Query
            If($PScmdlet.ParameterSetName -eq 'Remove'){$Query = "MATCH (n) WHERE n.name='$Node' REMOVE n.$Property"}
            Else{$Query = "MATCH (n) WHERE n.name='$Node' SET n.$Property={Value}"}
            $Body = "{`"query`" : `"$Query`",`"params`" : { `"Value`" : `"$Value`" }}" 
            Write-verbose $Body
            # Call
            $Call = Try{(Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body).data.data.name}Catch{$Error[0].Exception}
            $Result += $Call
            }
        }
    End{
        Return $Result -ne ''
        }
    }


############################################################################ NodeCreate

<#
.Synopsis
   Create Nodes
.DESCRIPTION
   Add Node to Bloodhound DB
.EXAMPLE
   NodeCreate -User 'Bob'
.EXAMPLE
   'john','bob'| NodeCreate -User
.INPUTS
   Input Node name
.OUTPUTS
   None
.NOTES
   refresh node list included
.COMPONENT
   This cmdlet belongs to CypherDog.psm1
.ROLE
   This cmdlet belongs to CypherDog.psm1
.FUNCTIONALITY
   Add Nodes to Bloodhound DB
#>
function Invoke-CypherNodeCreate{
    [CmdletBinding()]
    [Alias('NodeCreate')]
    Param(
        # Switch Node type User
        [Parameter(Mandatory=$true,ParameterSetName='User')][Switch]$User,
        # Switch Node type Group
        [Parameter(Mandatory=$true,ParameterSetName='Group')][Switch]$Group,
        # Switch Node Type Computer
        [Parameter(Mandatory=$true,ParameterSetName='Computer')][Switch]$Computer,
        # String name
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)][String[]]$Name
        )
    Begin{
        $Type=$PSCmdlet.ParameterSetName
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        # Prep empty result
        $Result = @()
        }
    Process{
        Foreach($Obj in $Name){
            Write-Verbose "Creating $type Name: $Obj"
            $Query = "MERGE (n:$Type {name: '$Obj'})"
            $Body = "{`"query`" : `"$Query`"}" 
            Write-verbose $Addr
            Write-verbose $Body
            # Try Call
		    $Result += Try{$Null = Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
            }
        # Refresh Nodes
        $null = Node -Refresh
        }
    End{$Result}
    }

############################################################################ NodeDelete

<#
.Synopsis
   Delete Nodes
.DESCRIPTION
   Delete Node from Bloodhound DB
.EXAMPLE
   NodeDelete -User Bob
.EXAMPLE
   'john','bob'| NodeDelete -User
.INPUTS
   Input Node Names
.OUTPUTS
   None
.NOTES
   Node list refresh included
.COMPONENT
   This cmdlet belongs to CypherDog.psm1
.ROLE
   This cmdlet belongs to CypherDog.psm1
.FUNCTIONALITY
   Delete Node from Bloodhound DB
#>
function Invoke-CypherNodeDelete{
    [CmdletBinding()]
    [Alias('NodeDelete')]
    Param(
        # Switch Node type User
        [Parameter(Mandatory=$true,ParameterSetName='User')][Switch]$User,
        # Switch Node type Group
        [Parameter(Mandatory=$true,ParameterSetName='Group')][Switch]$Group,
        # Switch Node Type Computer
        [Parameter(Mandatory=$true,ParameterSetName='Computer')][Switch]$Computer
        )
    DynamicParam{
        # Grab Matching Node List
        Switch($PSCmdlet.ParameterSetName){
            'User'{$NodeList=$Global:CypherDog.User}
            'Group'{$NodeList=$Global:CypherDog.Group}
            'Computer'{$NodeList=$Global:CypherDog.Computer}
            }
        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        ## Name
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.Position = 0
        $Attrib1.ValueFromPipeline=$true
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

		#return Dictionary
		return $Dictionary
        }
    Begin{
        $Type = $PSCmdlet.ParameterSetName
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        # Prep empty result
        $Result = @()
        }
    Process{
        Foreach($Obj in $DynParam1.value){
            Write-Verbose "Deleting $type Name: $Obj"
            $Query = "MATCH (n:$type {name: '$Obj'}) DETACH DELETE n"
            $Body = "{`"query`" : `"$Query`"}" 
            Write-verbose $Addr
            Write-verbose $Body
            # Try Call
		    $Result += Try{$Null = Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
            }
        # Refresh Nodes
        $null = Node -Refresh
        }
    End{$Result}
    }


################################################################################## Edge

<#
.Synopsis
   List Bloodhound Nodes by Edge 
.DESCRIPTION
   Retrieve BloodHound Nodes with specified relationship to specified target
.EXAMPLE
   Edge -MemberOfGroup -Name AUDIT_A@EXTERNAL.LOCAL -Return Users
.EXAMPLE
   Edge -AdminToComputer -Name APOLLO.EXTERNAL.LOCAL -Return Groups
.INPUTS
   Target Node
.OUTPUTS
   Node Names
.NOTES
   General notes
.COMPONENT
   This Cmdlet belongs to CyperDog Module
.ROLE
   List Bloodhound Nodes by Edge
.FUNCTIONALITY
   Retrieve BloodHound Nodes with specified relationship to specified target
#>
function Invoke-CypherEdge{
	[CmdletBinding()]
	[Alias('Edge')]
	param(
		# Edge: MemberOfGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='MemberOfGroup')][Switch]$MemberOfGroup,
		# Edge: AdminToComputer (Input: C - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AdminToComputer')][Switch]$AdminToComputer,
		# Edge: SessionFromUser (Input: U - Return: C)
		[Parameter(Mandatory=$True,ParameterSetname='SessionFromUser')][Switch]$SessionFromUser,
		# Edge: SetPasswordOfUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='SetPasswordOfUser')][Switch]$SetPasswordOfUser,
		# Edge: AddMemberToGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AddMemberToGroup')][Switch]$AddMemberToGroup,
		# Edge: AllExtendedOnUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AllExtendedOnUser')][Switch]$AllExtendedOnUser,
		# Edge: AllExtendedOnGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AllExtendedOnGroup')][Switch]$AllExtendedOnGroup,
		# Edge: AllGenericOnUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AllGenericOnUser')][Switch]$AllGenericOnUser,
		# Edge: AllGenericOnGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='AllGenericOnGroup')][Switch]$AllGenericOnGroup,
		# Edge: WriteGenericOnUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteGenericOnUser')][Switch]$WriteGenericOnUser,
		# Edge: WriteGenericOnGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteGenericOnGroup')][Switch]$WriteGenericOnGroup,
		# Edge: WriteOwnerOnUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteOwnerOnUser')][Switch]$WriteOwnerOnUser,
		# Edge: WriteOwnerOnGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteOwnerOnGroup')][Switch]$WriteOwnerOnGroup,
		# Edge: WriteDACLOnUser (Input: U - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteDACLOnUser')][Switch]$WriteDACLOnUser,
		# Edge: WriteDACLOnGroup (Input: G - Return: U|G|C)
		[Parameter(Mandatory=$True,ParameterSetname='WriteDACLOnGroup')][Switch]$WriteDACLOnGroup,
		# Edge: TrustedByDomain (Input: D - Return: D)
		[Parameter(Mandatory=$True,ParameterSetname='TrustedByDomain')][Switch]$TrustedByDomain
		)
	DynamicParam{
		# Prep Target Lists
		$ValidSetU = $Global:CypherDog.User
		$ValidSetG = $Global:CypherDog.Group
		$ValidSetC = $Global:CypherDog.Computer
		$ValidSetD = $Global:CypherDog.Domain
		# Select ValidateSets for Dynamic Parameters
		Switch($PSCmdlet.ParameterSetName){
			'MemberOfGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'AdminToComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups','Computers'}
			'SessionFromUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Computers'}
			'SetPasswordOfUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'AddMemberToGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'AllExtendedOnUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'AllExtendedOnGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'AllGenericOnUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'AllGenericOnGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteGenericOnUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteGenericOnGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteOwnerOnUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteOwnerOnGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteDACLOnUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups','Computers'}
			'WriteDACLOnGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups','Computers'}
			'TrustedByDomain'{$ValidSet = $ValidSetD; $ValidSet2 = 'Domains'}
			}
		# Create runtime Dictionary for this ParameterSet
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		# Create Attribute Object - Name
		$Attrib = New-Object System.Management.Automation.ParameterAttribute
		$Attrib.Position = 1
		$Attrib.Mandatory = $True
		$Attrib.ValueFromPipeline = $true
		$Attrib.HelpMessage = 'Specify target name(s)'
		# Create AttributeCollection object for the attribute Object
		$Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
		# Add our custom attribute to collection
		$Collection.Add($Attrib)
		# Add Validate Set to attribute collection     
		$ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($ValidSet)
		$Collection.Add($ValidateSet)
		# Create Runtime Parameter with matching attribute collection
		$DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Name',[String[]],$Collection)
		# Add Runtime Param to dictionary
		$Dictionary.Add('Name',$dynParam)

		# Create Attribute Object - Return
		$Attrib2 = New-Object System.Management.Automation.ParameterAttribute
		$Attrib2.Position = 2
		$Attrib2.Mandatory = $True
		$Attrib2.HelpMessage = 'Specify Type of Node to Return'
		# Create AttributeCollection object for the attribute Object
		$Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
		# Add our custom attribute to collection
		$Collection2.Add($Attrib2)
		# Add Validate Set to attribute collection     
		$ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ValidSet2)
		$Collection2.Add($ValidateSet2)
		# Create Runtime Parameter with matching attribute collection
		$DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('Return',[String],$Collection2)
		# Add Runtime Param to dictionary
		$Dictionary.Add('Return',$dynParam2)

        If($PSCmdlet.ParameterSetName -match "MemberOf"){
            ## Max Degree
            # Create Attribute Object - Degree
            $Attrib3 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib3.Mandatory = $false
            $Attrib3.HelpMessage = "Enter Relationship Max Degree"
            # Create AttributeCollection object for the attribute Object
            $Collection3 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute
            $Collection3.Add($Attrib3)
            # Add Validate Pattern to attribute collection     
		    $ValidatePat3=new-object System.Management.Automation.ValidatePatternAttribute('^\d$|\*')
		    $Collection3.Add($ValidatePat3)
            # Create Runtime Parameter with matching attribute collection
            $DynParam3 = New-Object System.Management.Automation.RuntimeDefinedParameter('Degree', [String], $Collection3)
            # Add all Runtime Params to dictionary
            $Dictionary.Add('Degree',$dynParam3)
            }

        ## Query to Clipboard
        # Create Attribute Object - Clip
        $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib0.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection0.Add($Attrib0)
        # Create Runtime Parameter with matching attribute collection
        $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Clip', [Switch], $Collection0)
        # Add Runtime Param to dictionary
		$Dictionary.Add('Clip',$dynParam0)

		#return Dictionary
		return $Dictionary
		}

	Begin{
        if($PScmdlet.ParameterSetName -match 'MemberOf' -AND !$DynParam3.IsSet){$DynParam3.Value=1}
        if($PScmdlet.ParameterSetName -match 'MemberOf' -AND $DynParam3.Value -eq '*'){$DynParam3.Value=$Null}
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        Write-Verbose $Addr
		# Populate Query vars
		Switch($PSCmdlet.ParameterSetName){
			'MemberOfGroup'{$EdgeName='MemberOf';$InputType='Group'}
			'AdminToComputer'{$EdgeName='AdminTo';$InputType='Computer'}
			'SessionFromUser'{$EdgeName='HasSession';$InputType='User'}
			'SetPasswordOfUser'{$EdgeName='ForceChangePassword';$InputType='User'}
			'AddMemberToGroup'{$EdgeName='AddMembers';$InputType='Group'}
			'AllExtendedOnUser'{$EdgeName='AllExtendedRights';$InputType='User'}
			'AllExtendedOnGroup'{$EdgeName='AllExtendedRights';$InputType='Group'}
			'AllGenericOnUser'{$EdgeName='GenericAll';$InputType='User'}
			'AllGenericOnGroup'{$EdgeName='GenericAll';$InputType='Group'}
			'WriteGenericOnUser'{$EdgeName='GenericWrite';$InputType='User'}
			'WriteGenericOnGroup'{$EdgeName='GenericWrite';$InputType='Group'}
			'WriteOwnerOnUser'{$EdgeName='WriteOwner';$InputType='User'}
			'WriteOwnerOnGroup'{$EdgeName='WriteOwner';$InputType='Group'}
			'WriteDACLOnUser'{$EdgeName='WriteDACL';$InputType='User'}
			'WriteDACLOnGroup'{$EdgeName='WriteDACL';$InputType='Group'}
			'TrustedByDomain'{$EdgeName='TrustedBy';$InputType='Domain'}
			}
		$OutputType=$dynParam2.Value.trimEnd('s')
        #Result collector
        $Result = @()
		}
	Process{
        foreach($Target in $DynParam.Value){
            # Prep Call
		    $Query = "MATCH (A:$OutputType),(B:$InputType {name: {ParamB}}) MATCH p=(A)-[r:$EdgeName*1..$($DynParam3.value)]->(B) RETURN A"
		    $Body = "{`"query`" : `"$Query`",`"params`" : { `"ParamB`" : `"$Target`" }}"
		    #Verbose
		    Write-Verbose $Body
            # Try Call
		    $Call = Try{(Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body).data.data.name}Catch{$Error[0].Exception}
            $Result += $Call
            }
        # If ClipBoard
        if($DynParam0.value -eq $true){$Query.replace('{ParamB}',"'$Target'") | Set-Clipboard}
        }
	End{
        # Return Result
		Return $Result | Sort -unique
		}
	}


################################################################################# EdgeR

<#
.Synopsis
   List Bloodhound Nodes by Edge - Reverse
.DESCRIPTION
   Retrieve BloodHound Nodes with specified relatioship to specified target
.EXAMPLE
   Invoke-CypherEdgeR -ParentOfUser -Name ACHAVARIN@EXTERNAL.LOCAL -Return Groups 
.EXAMPLE
   EdgeR -ParentOfUser ACHAVARIN@EXTERNAL.LOCAL -Return Groups
.INPUTS
   Target Node
.OUTPUTS
   Node Names
.NOTES
   Return 
.COMPONENT
   This Cmdlet belongs to CyperDog Module
.ROLE
   List Bloodhound Nodes by Edge - Reverse
.FUNCTIONALITY
   Retrieve BloodHound Nodes with specified relationship to specified target
#>
function Invoke-CypherEdgeR{
	[CmdletBinding()]
	[Alias('EdgeR')]
	param(
		# Edge: ParentOfUser (Input: U - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='ParentOfUser')][Switch]$ParentOfUser,
		# Edge: ParentOfGroup (Input: G - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='ParentOfGroup')][Switch]$ParentOfGroup,
		# Edge: ParentOfComputer (Input: C - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='ParentOfComputer')][Switch]$ParentOfComputer,
		# Edge: AdminByUser (Input: U - Return: C)
		[Parameter(Mandatory=$True,ParameterSetname='AdminByUser')][Switch]$AdminByUser,
		# Edge: AdminByGroup (Input: G - Return: C)
		[Parameter(Mandatory=$True,ParameterSetname='AdminByGroup')][Switch]$AdminByGroup,
		# Edge: AdminByComputer (Input: C - Return: C)
		[Parameter(Mandatory=$True,ParameterSetname='AdminByComputer')][Switch]$AdminByComputer,
		# Edge: SessionOnComputer (Input: C - Return: U)
		[Parameter(Mandatory=$True,ParameterSetname='SessionOnComputer')][Switch]$SessionOnComputer,
		# Edge: PasswordSetByUser (Input: U - Return: U)
		[Parameter(Mandatory=$True,ParameterSetname='PasswordSetByUser')][Switch]$PasswordSetByUser,
		# Edge: PasswordSetByGroup (Input: G - Return: U)
		[Parameter(Mandatory=$True,ParameterSetname='PasswordSetByGroup')][Switch]$PasswordSetByGroup,
		# Edge: PasswordSetByComputer (Input: C - Return: U)
		[Parameter(Mandatory=$True,ParameterSetname='PasswordSetByComputer')][Switch]$PasswordSetByComputer,
		# Edge: MemberAddByUser (Input: U - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='MemberAddByUser')][Switch]$MemberAddByUser,
		# Edge: MemberAddByGroup (Input: G - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='MemberAddByGroup')][Switch]$MemberAddByGroup,
		# Edge: MemberAddByComputer (Input: C - Return: G)
		[Parameter(Mandatory=$True,ParameterSetname='MemberAddByComputer')][Switch]$MemberAddByComputer,
		# Edge: ExtendedAllByUser (Input: U - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='ExtendedAllByUser')][Switch]$ExtendedAllByUser,
		# Edge: ExtendedAllByGroup (Input: G - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='ExtendedAllByGroup')][Switch]$ExtendedAllByGroup,
		# Edge: ExtendedAllByComputer (Input: C - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='ExtendedAllByComputer')][Switch]$ExtendedAllByComputer,
		# Edge: GenericAllByUser (Input: U - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericAllByUser')][Switch]$GenericAllByUser,
		# Edge: GenericAllByGroup (Input: G - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericAllByGroup')][Switch]$GenericAllByGroup,
		# Edge: GenericAllByComputer (Input: C - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericAllByComputer')][Switch]$GenericAllByComputer,
		# Edge: GenericWriteByUser (Input: U - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericWriteByUser')][Switch]$GenericWriteByUser,
		# Edge: GenericWriteByGroup (Input: G - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericWriteByGroup')][Switch]$GenericWriteByGroup,
		# Edge: GenericWriteByComputer (Input: C - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='GenericWriteByComputer')][Switch]$GenericWriteByComputer,
		# Edge: OwnerWriteByUser (Input: U - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='OwnerWriteByUser')][Switch]$OwnerWriteByUser,
		# Edge: OwnerWriteByGroup (Input: G - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='OwnerWriteByGroup')][Switch]$OwnerWriteByGroup,
		# Edge: OwnerWriteByComputer (Input: C - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='OwnerWriteByComputer')][Switch]$OwnerWriteByComputer,
		# Edge: DACLWriteByUser (Input: U - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='DACLWriteByUser')][Switch]$DACLWriteByUser,
		# Edge: DACLWriteByGroup (Input: G - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='DACLWriteByGroup')][Switch]$DACLWriteByGroup,
		# Edge: DACLWriteByComputer (Input: C - Return: U|G)
		[Parameter(Mandatory=$True,ParameterSetname='DACLWriteByComputer')][Switch]$DACLWriteByComputer,
		# Edge: TrustingDomain (Input: D - Return: D)
		[Parameter(Mandatory=$True,ParameterSetname='TrustingDomain')][Switch]$TrustingDomain
		)
	DynamicParam{
		# Prep Target Lists
		$ValidSetU = $Global:CypherDog.User
		$ValidSetG = $Global:CypherDog.Group
		$ValidSetC = $Global:CypherDog.Computer
		$ValidSetD = $Global:CypherDog.Domain
		# Select ValidateSets for Dynamic Parameters
		Switch($PSCmdlet.ParameterSetName){
			'ParentOfUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Groups'}
			'ParentOfGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Groups'}
			'ParentOfComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Groups'}
			'AdminByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Computers'}
			'AdminByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Computers'}
			'AdminByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Computers'}
			'SessionOnComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users'}
			'PasswordSetByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users'}
			'PasswordSetByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users'}
			'PasswordSetByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users'}
			'MemberAddByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Groups'}
			'MemberAddByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Groups'}
			'MemberAddByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Groups'}
			'ExtendedAllByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups'}
			'ExtendedAllByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups'}
			'ExtendedAllByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups'}
			'GenericAllByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups'}
			'GenericAllByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups'}
			'GenericAllByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups'}
			'GenericWriteByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups'}
			'GenericWriteByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups'}
			'GenericWriteByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups'}
			'OwnerWriteByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups'}
			'OwnerWriteByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups'}
			'OwnerWriteByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups'}
			'DACLWriteByUser'{$ValidSet = $ValidSetU; $ValidSet2 = 'Users','Groups'}
			'DACLWriteByGroup'{$ValidSet = $ValidSetG; $ValidSet2 = 'Users','Groups'}
			'DACLWriteByComputer'{$ValidSet = $ValidSetC; $ValidSet2 = 'Users','Groups'}
			'TrustingDomain'{$ValidSet = $ValidSetD; $ValidSet2 = 'Domains'}
			}
		# Create runtime Dictionary for this ParameterSet
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		# Create Attribute Object - Name
		$Attrib = New-Object System.Management.Automation.ParameterAttribute
		$Attrib.Position = 1
		$Attrib.Mandatory = $True
		$Attrib.ValueFromPipeline = $true
		$Attrib.HelpMessage = 'Specify target name'
		# Create AttributeCollection object for the attribute Object
		$Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
		# Add our custom attribute to collection
		$Collection.Add($Attrib)
		# Add Validate Set to attribute collection     
		$ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($ValidSet)
		$Collection.Add($ValidateSet)
		# Create Runtime Parameter with matching attribute collection
		$DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Name',[String[]],$Collection)
		# Add Runtime Param to dictionary
		$Dictionary.Add('Name',$dynParam)

		# Create Attribute Object -  Return 
		$Attrib2 = New-Object System.Management.Automation.ParameterAttribute
		$Attrib2.Position = 2
		$Attrib2.Mandatory = $True
		$Attrib2.HelpMessage = 'Specify Type of Node to Return'
		# Create AttributeCollection object for the attribute Object
		$Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
		# Add our custom attribute to collection
		$Collection2.Add($Attrib2)
		# Add Validate Set to attribute collection     
		$ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ValidSet2)
		$Collection2.Add($ValidateSet2)
		# Create Runtime Parameter with matching attribute collection
		$DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('Return',[String],$Collection2)
		# Add Runtime Param to dictionary
		$Dictionary.Add('Return',$dynParam2)
        
        ## Max Degree
        If($PSCmdlet.ParameterSetName -match "ParentOf"){
            
            # Create Attribute Object - Degree
            $Attrib3 = New-Object System.Management.Automation.ParameterAttribute
            $Attrib3.Mandatory = $false
            $Attrib3.HelpMessage = "Enter Relationship Max Degree"
            # Create AttributeCollection object for the attribute Object
            $Collection3 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            # Add our custom attribute
            $Collection3.Add($Attrib3)
            # Add Validate Pattern to attribute collection     
		    $ValidatePat3=new-object System.Management.Automation.ValidatePatternAttribute('^\d$|\*')
		    $Collection3.Add($ValidatePat3)
            # Create Runtime Parameter with matching attribute collection
            $DynParam3 = New-Object System.Management.Automation.RuntimeDefinedParameter('Degree', [string], $Collection3)
            # Add all Runtime Params to dictionary
            $Dictionary.Add('Degree',$dynParam3)
            }
        ## Query to Clipboard
        # Create Attribute Object - clip
        $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib0.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection0.Add($Attrib0)
        # Create Runtime Parameter with matching attribute collection
        $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Clip', [Switch], $Collection0)
        # Add Runtime Param to dictionary
		$Dictionary.Add('Clip',$dynParam0)
        
        #return Dictionary
		return $Dictionary
		}
	Begin{
        if($PScmdlet.ParameterSetName -match 'ParentOf' -AND !$DynParam3.IsSet){$DynParam3.Value=1}
        if($PScmdlet.ParameterSetName -match 'ParentOf' -AND $DynParam3.Value -eq '*'){$DynParam3.Value=$Null}
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        Write-verbose $Addr
		# Populate Query vars
		Switch($PSCmdlet.ParameterSetName){
			'ParentOfUser'{$EdgeName='MemberOf';$InputType='User'}
			'ParentOfGroup'{$EdgeName='MemberOf';$InputType='Group'}
			'ParentOfComputer'{$EdgeName='MemberOf';$InputType='Computer'}
			'AdminByUser'{$EdgeName='AdminTo';$InputType='User'}
			'AdminByGroup'{$EdgeName='AdminTo';$InputType='Group'}
			'AdminByComputer'{$EdgeName='AdminTo';$InputType='Computer'}
			'SessionOnComputer'{$EdgeName='HasSession';$InputType='Computer'}
			'PasswordSetByUser'{$EdgeName='ForceChangePassword';$InputType='User'}
			'PasswordSetByGroup'{$EdgeName='ForceChangePassword';$InputType='Group'}
			'PasswordSetByComputer'{$EdgeName='ForceChangePassword';$InputType='Computer'}
			'MemberAddByUser'{$EdgeName='AddMembers';$InputType='User'}
			'MemberAddByGroup'{$EdgeName='AddMembers';$InputType='Group'}
			'MemberAddByComputer'{$EdgeName='AddMembers';$InputType='Computer'}
			'ExtendedAllByUser'{$EdgeName='AllExtendedRights';$InputType='User'}
			'ExtendedAllByGroup'{$EdgeName='AllExtendedRights';$InputType='Group'}
			'ExtendedAllByComputer'{$EdgeName='AllExtendedRights';$InputType='Computer'}
			'GenericAllByUser'{$EdgeName='GenericAll';$InputType='User'}
			'GenericAllByGroup'{$EdgeName='GenericAll';$InputType='Group'}
			'GenericAllByComputer'{$EdgeName='GenericAll';$InputType='Computer'}
			'GenericWriteByUser'{$EdgeName='GenericWrite';$InputType='User'}
			'GenericWriteByGroup'{$EdgeName='GenericWrite';$InputType='Group'}
			'GenericWriteByComputer'{$EdgeName='GenericWrite';$InputType='Computer'}
			'OwnerWriteByUser'{$EdgeName='WriteOwner';$InputType='User'}
			'OwnerWriteByGroup'{$EdgeName='WriteOwner';$InputType='Group'}
			'OwnerWriteByComputer'{$EdgeName='WriteOwner';$InputType='Computer'}
			'DACLWriteByUser'{$EdgeName='WriteDACL';$InputType='User'}
			'DACLWriteByGroup'{$EdgeName='WriteDACL';$InputType='Group'}
			'DACLWriteByComputer'{$EdgeName='WriteDACL';$InputType='Computer'}
			'TrustingDomain'{$EdgeName='TrustedBy';$InputType='Domain'}
			}
		# Populate Call Vars
		$OutputType=$dynParam2.Value.trimEnd('s')
		
        $Result = @()
        }
	Process{
        foreach($Target in $DynParam.Value){
		    # Prep Call
		    $Query ="MATCH (A:$OutputType),(B:$InputType {name: {ParamB}}) MATCH p=(A)<-[r:$EdgeName*1..$($DynParam3.value)]-(B) RETURN A"
		    $Body = "{`"query`" : `"$Query`",`"params`" : { `"ParamB`" : `"$Target`" }}"
		    #Verbose
		    Write-Verbose $Body
        
            # Try Call
		    $Call = Try{(Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body).data.data.name}Catch{$Error[0].Exception}
            $Result += $Call
            }
        # If ClipBoard
        if($DynParam0.value -eq $true){$Query.replace('{ParamB}',"'$Target'") | Set-Clipboard}
        }
	End{
        # Return Result
		Return $Result | sort -unique
		}
	}


############################################################################ EdgeCreate

<#
.Synopsis
   Create Edges
.DESCRIPTION
   Create new Edge between Nodes
.EXAMPLE
   EdgeCreate -UserToUser john -EdgeType IsBetter -To bob
.INPUTS
   Input from/edge/to
.OUTPUTS
   None
.NOTES
   General notes
.COMPONENT
   This Cmdlet belongs to CyperDog Module
.FUNCTIONALITY
   Create new Edge between Nodes
#>
Function Invoke-CypherEdgeCreate{
    [CmdletBinding()]
    [Alias('EdgeCreate')]
    Param(
        #Create Edge from User to Group
        [Parameter(Mandatory=$true,ParameterSetname='UserToGroup')][Alias('UTG')][Switch]$UserToGroup,
        #Create Edge from User to User
        [Parameter(Mandatory=$true,ParameterSetname='UserToUser')][Alias('UTU')][Switch]$UserToUser,
        #Create Edge from User to Computer
        [Parameter(Mandatory=$true,ParameterSetname='UserToComputer')][Alias('UTC')][Switch]$UserToComputer,
        #Create Edge from Group to User
        [Parameter(Mandatory=$true,ParameterSetname='GroupToUser')][Alias('GTU')][Switch]$GroupToUser,
        #Create Edge from Group to Group
        [Parameter(Mandatory=$true,ParameterSetname='GroupToGroup')][Alias('GTG')][Switch]$GroupToGroup,
        #Create Edge from Group to Computer
        [Parameter(Mandatory=$true,ParameterSetname='GroupToComputer')][Alias('GTC')][Switch]$GroupToComputer,
        #Create Edge from Computer to User
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToUser')][Alias('CTU')][Switch]$ComputerToUser,
        #Create Edge from Computer to Group
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToGroup')][Alias('CTG')][Switch]$ComputerToGroup,
        #Create Edge from Computer to computer
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToComputer')][Alias('CTC')][Switch]$ComputerToComputer,
        
        #EdgeType
        [Parameter(Mandatory=$true)][Alias('Type')][String]$EdgeType 
        )
    DynamicParam{
        $UserList = $Global:CypherDog.User
        $GroupList = $Global:CypherDog.Group
        $ComputerList = $Global:CypherDog.Computer
        
        $Split0 = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $Split1 = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]
        
        ## Match Lists for each ParamSet
        $FromList = Get-Variable "${Split0}List" -ValueOnly
        $ToList   = Get-Variable "${Split1}List" -ValueOnly

        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        ## From 
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.Position = 0
        $Attrib1.ValueFromPipeline = $true
        $Attrib1.HelpMessage = "Enter Start Node"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($FromList)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('From', [String], $Collection1)
        
        ## To
        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $true
        $Attrib2.Position = 1
        $Attrib2.HelpMessage = "Enter End Node"
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection2.Add($Attrib2)
        # Add Validate Set     
        $ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ToList)
        $Collection2.Add($ValidateSet2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('To', [String], $Collection2)
        
        # Add all Runtime Params to dictionary
        $Dictionary.Add('From', $dynParam1)
        $Dictionary.Add('To', $dynParam2)
            
        ## Return Dictionary
        return $Dictionary
        }
    Begin{
        # Prep cmdlet vars
        $SrcType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $TgtType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]
        $Tgt=$DynParam2.Value
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        # Prep empty result
        $Result = @()
        }
    Process{
        # Foreach Source
        Foreach($Src in $DynParam1.Value){
            Write-Verbose "Creating Edge $EdgeType from $Src to $Tgt"
            $Query = "MATCH (n:$SrcType {name: '$Src'}) MATCH (m:$TgtType {name: '$Tgt'}) CREATE (n)-[r:$EdgeType]->(m)"
            $Body = "{`"query`" : `"$Query`"}" 
            Write-verbose $Addr
            Write-verbose $Body
            # Try Call
		    $Result += Try{$Null = Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
            }
        # Refresh Nodes
        $Null = Node -Refresh
        }
    End{}
    }

############################################################################ EdgeDelete

<#
.Synopsis
   Delete Edges
.DESCRIPTION
    Delete Edges from Bloodhound DB
.EXAMPLE
   EdgeDelete -UserToUser -From john -EdgeType IsBetter -To bob
.INPUTS
   None
.OUTPUTS
   NoneOutput from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   This Cmdlet belongs to CyperDog Module
.FUNCTIONALITY
   Delete Edges from Bloodhound DB
#>
Function Invoke-CypherEdgeDelete{
    [CmdletBinding()]
    [Alias('EdgeDelete')]
    Param(
        #Create Edge from User to Group
        [Parameter(Mandatory=$true,ParameterSetname='UserToGroup')][Alias('UTG')][Switch]$UserToGroup,
        #Create Edge from User to User
        [Parameter(Mandatory=$true,ParameterSetname='UserToUser')][Alias('UTU')][Switch]$UserToUser,
        #Create Edge from User to Computer
        [Parameter(Mandatory=$true,ParameterSetname='UserToComputer')][Alias('UTC')][Switch]$UserToComputer,
        #Create Edge from Group to User
        [Parameter(Mandatory=$true,ParameterSetname='GroupToUser')][Alias('GTU')][Switch]$GroupToUser,
        #Create Edge from Group to Group
        [Parameter(Mandatory=$true,ParameterSetname='GroupToGroup')][Alias('GTG')][Switch]$GroupToGroup,
        #Create Edge from Group to Computer
        [Parameter(Mandatory=$true,ParameterSetname='GroupToComputer')][Alias('GTC')][Switch]$GroupToComputer,
        #Create Edge from Computer to User
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToUser')][Alias('CTU')][Switch]$ComputerToUser,
        #Create Edge from Computer to Group
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToGroup')][Alias('CTG')][Switch]$ComputerToGroup,
        #Create Edge from Computer to computer
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToComputer')][Alias('CTC')][Switch]$ComputerToComputer,
        
        #EdgeType
        [Parameter(Mandatory=$true)][Alias('Type')][String]$EdgeType
        )
    DynamicParam{
        # Get Node lists
        $UserList = $Global:CypherDog.User
        $GroupList = $Global:CypherDog.Group
        $ComputerList = $Global:CypherDog.Computer
        
        #Split ParamSetName
        $Split0 = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $Split1 = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]
        
        ## Match Lists for each ParamSet
        $FromList = Get-Variable "${Split0}List" -ValueOnly
        $ToList   = Get-Variable "${Split1}List" -ValueOnly
        
        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        ## From
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.Position = 0
        $Attrib1.ValueFromPipeline = $true
        $Attrib1.HelpMessage = "Enter source Node name"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection1.Add($Attrib1)
        # Add Validate Set     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($FromList)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('From', [String[]], $Collection1)
        
        # Add all Runtime Params to dictionary
        $Dictionary.Add('From', $dynParam1)        
        
        ## To
        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $true
        $Attrib2.Position = 0
        $Attrib2.ValueFromPipeline = $true
        $Attrib2.HelpMessage = "Enter target Node name"
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection2.Add($Attrib2)
        # Add Validate Set     
        $ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ToList)
        $Collection2.Add($ValidateSet2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('To', [String[]], $Collection2)
        
        # Add all Runtime Params to dictionary
        $Dictionary.Add('To', $dynParam2)
            
        ## Return Dictionary
        return $Dictionary
        }
    Begin{
        # Prep cmdlet vars
        $SrcType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $TgtType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        # Prep empty result
        $Result = @()
        }
    Process{
        $Tgt = $DynParam2.Value
        # Foreach Source
        Foreach($Src in $DynParam1.Value){
            Write-Verbose "Removin Edge $EdgeType from ${SrcType}s $Src to $TgtType $Tgt"
            $Query = "MATCH (n:$SrcType {name: '$Src'})-[r:$EdgeType]-(m:$TgtType {name: '$Tgt'}) DELETE r"
            if($EdgeType = '*'){$Query = "MATCH (n:$SrcType {name: '$Src'})-[r]-(m:$TgtType {name: '$Tgt'}) DELETE r"}
            $Body = "{`"query`" : `"$Query`"}" 
            Write-verbose $Addr
            Write-verbose $Body
            # Try Call
		    $Result += Try{$Null = Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
            }
        # Refresh Nodes
        $Null = Node -Refresh
        }
    End{}
    }


################################################################################## Path

<#
.Synopsis
   Retrieve Bloodhound Path
.DESCRIPTION
   Retrieve Bloodhound Path
.EXAMPLE
   Path -UserToGroup -From ACHAVARIN@EXTERNAL.LOCAL -To 'DOMAIN ADMINS@INTERNAL.LOCAL'
   .EXAMPLE
   Path -UserToGroup -From ACHAVARIN@EXTERNAL.LOCAL -To 'DOMAIN ADMINS@INTERNAL.LOCAL' -Clip
   Paste clipboard into BloodHound Raw Query inout box to view graph
.INPUTS
   None
.OUTPUTS
   None
.NOTES
   General notes
.COMPONENT
   This Cmdlet belongs to CyperDog Module
.FUNCTIONALITY
   Retrieve Bloodhound Path
#>
function Invoke-CypherPath {
    [CmdletBinding()]
    [Alias('Path')]
    Param(
        #Request Path from User to Group
        [Parameter(Mandatory=$true,ParameterSetname='UserToGroup')][Alias('UTG')][Switch]$UserToGroup,
        #Request Path from User to User
        [Parameter(Mandatory=$true,ParameterSetname='UserToUser')][Alias('UTU')][Switch]$UserToUser,
        #Request Path from User to Computer
        [Parameter(Mandatory=$true,ParameterSetname='UserToComputer')][Alias('UTC')][Switch]$UserToComputer,
        #Request Path from Group to User
        [Parameter(Mandatory=$true,ParameterSetname='GroupToUser')][Alias('GTU')][Switch]$GroupToUser,
        #Request Path from Group to Group
        [Parameter(Mandatory=$true,ParameterSetname='GroupToGroup')][Alias('GTG')][Switch]$GroupToGroup,
        #Request Path from Group to Computer
        [Parameter(Mandatory=$true,ParameterSetname='GroupToComputer')][Alias('GTC')][Switch]$GroupToComputer,
        #Request Path from Computer to User
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToUser')][Alias('CTU')][Switch]$ComputerToUser,
        #Request Path from Computer to Group
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToGroup')][Alias('CTG')][Switch]$ComputerToGroup,
        #Request Path from Computer to computer
        [Parameter(Mandatory=$true,ParameterSetname='ComputerToComputer')][Alias('CTC')][Switch]$ComputerToComputer
        )
    DynamicParam{
        ## Get Lists for ValidateSets
        $UserList = $Global:CypherDog.User
        $GroupList = $Global:CypherDog.Group
        $ComputerList = $Global:CypherDog.Computer
        
        ## Match Lists for each ParamSet
        $FromList = Get-Variable "$($PScmdlet.ParameterSetName.replace('To','*').split('*')[0])List" -ValueOnly
        $ToList   = Get-Variable "$($PScmdlet.ParameterSetName.replace('To','*').split('*')[1])List" -ValueOnly
        
        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        ## From 
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.Position = 1
        $Attrib1.HelpMessage = "Enter Start Node"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($FromList)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('From', [String], $Collection1)
        
        ## To
        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $true
        $Attrib2.Position = 2
        $Attrib2.HelpMessage = "Enter End Node"
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection2.Add($Attrib2)
        # Add Validate Set     
        $ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ToList)
        $Collection2.Add($ValidateSet2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('To', [String], $Collection2)
        
        ## Query to Clipboard
        # Create Attribute Object
        $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib0.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection0.Add($Attrib0)
        # Create Runtime Parameter with matching attribute collection
        $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Clip', [Switch], $Collection0)

        # Add all Runtime Params to dictionary
        $Dictionary.Add('From', $dynParam1)
        $Dictionary.Add('To', $dynParam2)
        $Dictionary.Add('Clip', $dynParam0)
            
        ## Return Dictionary
        return $Dictionary
        }
    Begin{
		# Set Address and Headers
		$Addr = "http://$($Global:CypherDog.Connect.Host):$($Global:CypherDog.Connect.Port)/db/data/cypher"
		$Header=@{'Accept'='application/json; charset=UTF-8';'Content-Type'='application/json'}
        Write-verbose $Addr
        # Strip types
        $FromType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $ToType   = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]

        # Build Query
        $Query = "MATCH (A:$FromType {name: {ParamA}}), (B:$ToType {name: {ParamB}}), x=shortestPath((A)-[*1..]->(B)) RETURN x"
        $Body = "{`"query`" : `"$Query`",`"params`" : { `"ParamA`" : `"$($DynParam1.value)`", `"ParamB`" : `"$($DynParam2.value)`" }}"
        Write-verbose $Body
        }
	Process{
        if($DynParam0.value -eq $true){$Query.replace('{ParamA}',"'$($DynParam1.value)'").replace('{ParamB}',"'$($DynParam2.value)'") | Set-Clipboard}
        # Try Call
		$Result = Try{Invoke-RestMethod -Uri $Addr -Method Post -Headers $Header -Body $Body}Catch{$Error[0].Exception}
		# if no error > format result
        if($result.data -ne ''){
            $FinalObj = @()
            0..($Result.data.relationships.count -1)|%{
                $Props = @{
                    'Step'       = $_
                    'StartNode'  = (irm -uri $Result.data.nodes[$_] -Method Get -Headers $header).data.name 
                    'Edge'   = (irm -uri $Result.data.relationships[$_] -Method Get -Headers $header).type
                    'Direction'  = $Result.data.directions[$_]
                    'EndNode'    = (irm -uri $Result.data.nodes[$_+1] -Method Get -Headers $header).data.name
                    }
                $FinalObj += New-Object PSCustomObject -Property $props
                }
            $Result = $FinalObj | select 'Step','StartNode','Edge','Direction','EndNode'
            }
        Else{$result = $Null}
        }
	End{
        # Return Result
		Return $Result
		}
	}


############################################################################# PathQuery

<#
.Synopsis
   Cypher Query Builder
.DESCRIPTION
    Cypher Query Builder
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
   This Cmdlet belongs to CyperDog Module
.FUNCTIONALITY
    Cypher Query Builder
#>
function Invoke-CypherPathQuery{
    [Cmdletbinding()]
    [Alias('PathQuery')]
    Param(
        # Type
        [ValidateSet('ShortestPath','allShortestPaths','*')]
        [Parameter(Mandatory=$False)][String]$Type='AllShortestPaths',
        
        # Edges
        [ValidateSet('*','MemberOf','HasSession','AdminTo','WriteACL')]
        [Parameter(Mandatory=$False)][String[]]$Edges='*',
        
        # FromTypeToType
        [Parameter(mandatory=$true,ParameterSetName='UserToUser')][Switch]$UserToUser,
        [Parameter(mandatory=$true,ParameterSetName='UserToGroup')][Switch]$UserToGroup,
        [Parameter(mandatory=$true,ParameterSetName='UserToComputer')][Switch]$UserToComputer,
        [Parameter(mandatory=$true,ParameterSetName='GroupToUser')][Switch]$GroupToUser,
        [Parameter(mandatory=$true,ParameterSetName='GroupToGroup')][Switch]$GroupToGroup,
        [Parameter(mandatory=$true,ParameterSetName='GroupToComputer')][Switch]$GroupToComputer,
        [Parameter(mandatory=$true,ParameterSetName='ComputerToUser')][Switch]$ComputerToUser,
        [Parameter(mandatory=$true,ParameterSetName='ComputerToGroup')][Switch]$ComputerToGroup,
        [Parameter(mandatory=$true,ParameterSetName='ComputerToComputer')][Switch]$ComputerToComputer
        )
    DynamicParam{
        ## Get Lists for ValidateSets
        $UserList = $Global:CypherDog.User + @('*')
        $GroupList = $Global:CypherDog.Group + @('*')
        $ComputerList = $Global:CypherDog.Computer + @('*')
        
        ## Match Lists for each ParamSet
        $FromList = Get-Variable "$($PScmdlet.ParameterSetName.replace('To','*').split('*')[0])List" -ValueOnly
        $ToList   = Get-Variable "$($PScmdlet.ParameterSetName.replace('To','*').split('*')[1])List" -ValueOnly
        
        ## Dictionary
        # Create runtime Dictionary for this ParameterSet
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        ## From 
        # Create Attribute Object
        $Attrib1 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib1.Mandatory = $true
        $Attrib1.HelpMessage = "Enter Start Node"
        # Create AttributeCollection object for the attribute Object
        $Collection1 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute to collection
        $Collection1.Add($Attrib1)
        # Add Validate Set to attribute collection     
        $ValidateSet1=new-object System.Management.Automation.ValidateSetAttribute($FromList)
        $Collection1.Add($ValidateSet1)
        # Create Runtime Parameter with matching attribute collection
        $DynParam1 = New-Object System.Management.Automation.RuntimeDefinedParameter('From', [String[]], $Collection1)
        $Dictionary.Add('From', $dynParam1)
                
        ## To
        # Create Attribute Object
        $Attrib2 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib2.Mandatory = $true
        $Attrib2.HelpMessage = "Enter End Node"
        # Create AttributeCollection object for the attribute Object
        $Collection2 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection2.Add($Attrib2)
        # Add Validate Set     
        $ValidateSet2=new-object System.Management.Automation.ValidateSetAttribute($ToList)
        $Collection2.Add($ValidateSet2)
        # Create Runtime Parameter with matching attribute collection
        $DynParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter('To', [String[]], $Collection2)
        $Dictionary.Add('To', $dynParam2)
                
        ## MaxHop
        # Create Attribute Object
        $Attrib3 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib3.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection3 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection3.Add($Attrib3)
        # Create Runtime Parameter with matching attribute collection
        $DynParam3 = New-Object System.Management.Automation.RuntimeDefinedParameter('MaxHop', [Int], $Collection3)
        $Dictionary.Add('MaxHop', $dynParam3)

        ## Top
        # Create Attribute Object
        $Attrib4 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib4.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection4 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection4.Add($Attrib4)
        # Create Runtime Parameter with matching attribute collection
        $DynParam4 = New-Object System.Management.Automation.RuntimeDefinedParameter('Limit', [Int], $Collection4)
        $Dictionary.Add('Limit', $dynParam4)

        ## Reverse Query
        # Create Attribute Object
        $Attrib5 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib5.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection5 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection5.Add($Attrib5)
        # Create Runtime Parameter with matching attribute collection
        $DynParam5 = New-Object System.Management.Automation.RuntimeDefinedParameter('Reverse', [Switch], $Collection5)
        $Dictionary.Add('Reverse', $dynParam5)

        ## Union
        # Create Attribute Object
        $Attrib7 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib7.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection7 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection7.Add($Attrib7)
        # Create Runtime Parameter with matching attribute collection
        $DynParam7 = New-Object System.Management.Automation.RuntimeDefinedParameter('Union', [String[]], $Collection7)
        $Dictionary.Add('Union', $dynParam7)

        ## Query to Clipboard
        # Create Attribute Object
        $Attrib0 = New-Object System.Management.Automation.ParameterAttribute
        $Attrib0.Mandatory = $false
        # Create AttributeCollection object for the attribute Object
        $Collection0 = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        # Add our custom attribute
        $Collection0.Add($Attrib0)
        # Create Runtime Parameter with matching attribute collection
        $DynParam0 = New-Object System.Management.Automation.RuntimeDefinedParameter('Clip', [Switch], $Collection0)
        $Dictionary.Add('Clip', $dynParam0)
            
        ## Return Dictionary
        return $Dictionary
        }
    Begin{
        # get dyn param values
        if($DynParam1.IsSet){$from=@($DynParam1.Value)}
        if($DynParam2.IsSet){$To=@($DynParam2.Value)}
        if($DynParam3.IsSet){$MaxHop=$DynParam3.Value}
        if($DynParam4.IsSet){$Limit=$DynParam4.Value}
        if($DynParam5.IsSet){$Reverse=$DynParam5.Value}
        if($DynParam7.IsSet){$Union=@($DynParam7.Value)}
        if($DynParam0.IsSet){$Clip=$DynParam0.Value}
        
        # Prep Path type
        if($type -eq '*'){$Ptype=$Null}
        Else{$Ptype=$Type}

        # Prep Nodes types
        $FromType = $PScmdlet.ParameterSetName.replace('To','*').split('*')[0]
        $ToType   = $PScmdlet.ParameterSetName.replace('To','*').split('*')[1]

        # Prep Query Direction
        if($Reverse){$fwd=$Null;$Rew='<'}
        Else{$fwd='>';$Rew=$Null}

        # Prep -From
        if($From.count -gt 1 -AND $from -contains '*'){$SourceBlock =":$FromType"}
        ElseIf($From -eq '*'){$SourceBlock =":$FromType"}
        Else{$FromItems = "'" + ($From -join "','") + "'"; $SourceBlock =":$FromType {name: $FromItems}"}

        # prep -To
        if($To.count -gt 1 -AND $To -contains '*'){$TargetBlock =":$ToType"}
        ElseIf($To-eq '*'){$TargetBlock =":$ToType"}
        Else{$ToItems = "'" + ($to -join "','") + "'"; $TargetBlock =":$ToType {name: $ToItems}" }
        
        # Prep -Edges
        if($Edges.count -gt 1 -AND $Edges -contains '*'){$EdgeBlock=$Null}
        ElseIf($Edges -eq '*'){$EdgeBlock=$Null}
        Else{$EdgeBlock='R:'+($Edges -join "|")}
        
        # Prep ReturnBlock
        $ReturnBlock = ' RETURN P'
        If($limit -AND $Ptype -eq $Null){$ReturnBlock = " WITH P ORDER BY length(P) asc RETURN P LIMIT $Limit"}
        If($limit -AND $Ptype -ne $Null){$ReturnBlock = " RETURN P LIMIT $Limit"}
        }
    Process{
        $Query = "MATCH P=$PType((A$SourceBlock)$Rew-[$EdgeBlock*1..$MaxHop]-$fwd(B$targetBlock))$returnBlock"
        
        If($Union){Foreach($U in $Union){$Query += " UNION ALL $U"}}
        }
    End{
    If($Clip){$Query | Set-Clipboard}
        Return "$Query"
        }
    } 

