<#
	.SYNOPSIS
	Automatically removes computers accounts from Active Directory that haven't logged in this year.`
	Requires AD module.
#>

$computers = Get-ADComputer -Filter * -Property *
Foreach($comp in $computers){
	if($comp.lastLogonDate -notlike "*2018*"){
		Write-Host $comp.Name "-" $comp.lastLogonDate
#		Remove-ADComputer -Identity $comp.Name
	}
}