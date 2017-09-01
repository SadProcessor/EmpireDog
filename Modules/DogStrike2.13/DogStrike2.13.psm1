. $PSScriptRoot\DogStrike2.13.ps1


$Banner = @("
 ____          _____ _       _ _       
|    \ ___ ___|   __| |_ ___|_| |_ ___ 
|  |  | . | . |__   |  _|  _| | '_| -_|
|____/|___|_  |_____|_| |_| |_|_,_|___|2.13
~~~~~~~~~~|___|~~~~~~~~~~~~~~~~~~~~~~~
BloodHound & Empire - by SadProcessor
")



# Display Banner
Write-Host "$Banner" -ForegroundColor Cyan
Write-Host "`nModule Loaded..." -ForegroundColor Cyan

if(!$(get-command -Module CypherDog1.3)){try{Import-Module CypherDog1.3 -Force}catch{'Warning - CypherDog1.3 not found'}}
if(!$(get-command -Module EmpireStrike2.0)){try{Import-Module EmpireStrike2.0 -Force}catch{'Warning - EmpireStrike2.0 not found'}}