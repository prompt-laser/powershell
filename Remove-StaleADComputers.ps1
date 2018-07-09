<#
	.SYNOPSIS
	Automatically remove stale computer accounts that haven't logged in`
	in the past 6 monthsfrom Active Directory. Requires AD module.
#>

$computers = Get-ADComputer -Filter * -Property *
Foreach($comp in $computers){
	if($comp.lastLogonDate -lt (Get-Date).AddMOnths(-6)){
		Write-Host $comp.Name "-" $comp.lastLogonDate
		Remove-ADComputer -Identity $comp.Name -Confirm
	}
}