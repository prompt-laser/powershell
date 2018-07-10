<#
	.SYNOPSIS
	Remove stale computer accounts from Active Directory. Requires AD module.
	
	.DESCRIPTION
	Removes computer accounts that haven't logged in in more than the specified
	number of days. The default is 180 days.
	
	.PARAMETER Days
	Specifies minimum last logon in number of days prior to current date
	
	.EXAMPLE
	Remove-StaleADComputers
	Removes computers whose last logon was more than 180 days ago
	
	.EXAMPLE
	Remove-StaleADComputers -Days 90
	Removes computers whose last logon was more than 90 days ago
#>

param(
	[int]$Days = 180
)

$computers = Get-ADComputer -Filter * -Property *
Foreach($comp in $computers){
	if($comp.lastLogonDate -lt (Get-Date).AddDays($Days * -1)){
		Write-Host $comp.Name "-" $comp.lastLogonDate
		Remove-ADComputer -Identity $comp.Name -Confirm
	}
}