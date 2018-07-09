###################################################################################
#Tool for testing response time of multiple name servers for a DNS query
###################################################################################

<#
	.SYNOPSIS
	Tool for testing response time of DNS queries against multiple name servers. `
	Requires dnsclient module.
	
	.PARAMETER Server
	Specify one or more name servers to query
	
	.PARAMETER Address
	DNS name to query
	
	.PARAMETER Queries
	Number of times to query each server
	
	.PARAMETER Delay
	Number of seconds to wait between queries
#>

param(
	[Parameter(Mandatory=$true)]
	[string[]]$server,
	[Parameter(Mandatory=$true)]
	[string]$address,
	[int]$queries = 3,
	[int]$delay = 0
)

$theArray = @()

$i = 1
While($i -le $queries){
	ForEach($s in $server){
		$start = Get-Date
		Resolve-DNSName -name $address -server $s -type A
		$elapsed = ((Get-Date) - $start).milliseconds
		$theArray += New-Object PSObject -Property @{
			'Server' = $s
			'Response' = $elapsed
			'Time' = $start
		}
	}
	Sleep($delay)
	$i++
}

$output = @()
ForEach($s in $server){
	$sum = 0
	$i = 0
	ForEach($r in ($theArray | Where-Object Server -eq $s).Response){
		$sum = $sum + $r
		$i++
	}
	$output += New-Object PSObject -Property @{
		'Server' = $s
		'Minimum' = ($theArray | Where-Object Server -eq $s | Sort-Object Response | Select-Object -First 1).Response
		'Maximum' = ($theArray | Where-Object Server -eq $s | Sort-Object Response -Desc | Select-Object -First 1).Response
		'Average' = [int]($sum/$i)
	}
}

$output