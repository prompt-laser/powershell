<#
	.SYNOPSIS
	Tool for sending pop-up dialog boxes to computers.
#>

param(
	[Parameter(Mandatory=$true,Position=0)]
	[string]$Message,
	[Parameter(Position=1,ParameterSetName='Computers',Mandatory=$true)]
	[string[]]$ComputerName,
	[Parameter(ParameterSetName='Domain',Mandatory=$true)]
	[switch]$Domain = $false
)

If($domain -eq $true){
	Try{
		$computername = Get-ADComputer -filter * | Select-Object -ExpandProperty Name
	}Catch{
		Write-Host "Please install the ActiveDirectory module to use the domain feature."
	}
}Else{
	If($computername -eq "localhost"){
		msg * $message
	}Else{
		Invoke-Command -ComputerName $computername -ArgumentList $message -ScriptBlock {
			param($message)
			msg * $message
		}
	}
}