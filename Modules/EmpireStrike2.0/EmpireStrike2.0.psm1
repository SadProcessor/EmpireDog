. $PSScriptRoot\EmpireStrike2.0.ps1

#if(!$Global:EmpireTarget){Setup -verbose}

$Banner = @("
 _____           _         _____ _       _ _       
|   __|_____ ___|_|___ ___|   __| |_ ___|_| |_ ___ 
|   __|     | . | |  _| -_|__   |  _|  _| | '_| -_|
|_____|_|_|_|  _|_|_| |___|_____|_| |_| |_|_,_|___|2.0
~~~~~~~~~~~~|_|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Attack Mode PowerEmpire Wrapper - by SadProcessor
")


# Display Banner
Write-Host "$Banner" -ForegroundColor Cyan

if(!$Global:EmpireTarget){Setup -verbose}