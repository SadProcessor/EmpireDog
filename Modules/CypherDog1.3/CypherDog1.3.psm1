. $PSScriptRoot\CypherDog1.3.ps1

$Banner = @('
 _____         _           ____         
|     |_ _ ___| |_ ___ ___|    \ ___ ___ 
|   --| | | . |   | -_|  _|  |  | . | . |
|_____|_  |  _|_|_|___|_| |____/|___|_  |1.3
~~~~~~|___|_|~~~~~~~~~~~~~~~~~~~~~~~|___|
BloodHound Cypher via API by SadProcessor
')

# Display Banner
Write-Host "$Banner" -ForegroundColor Cyan
    
## Init CypherDog Obj on first load
if(!$Global:CypherDog.connect){

    #Create CypherDog Object (default connection values)
    $Props = @{
        'Connect'= @{'Host'='localHost';'Port'='7474'}
        'User' = @()
        'Group' = @()
        'Computer' = @()
        'Domain' = @()
        }
    $Global:CypherDog = New-Object PSCustomObject -Property $props
    
    #Fetch Initial Node Lists
    Node -Refresh

    }

$Dog = Get-Variable -Name CypherDog -ValueOnly
Write-Host $CypherDog -ForegroundColor Cyan
Write-Host "`nModule Loaded..." -ForegroundColor Cyan
########################################################################## END.O.SCRIPT