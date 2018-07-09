$computers = Get-ADComputer -Filter * -Property *
Foreach($comp in $computers){
	if($comp.lastLogonDate -notlike "*2018*"){
		Write-Host $comp.Name "-" $comp.lastLogonDate
		Remove-ADComputer -Identity $comp.Name
	}
}