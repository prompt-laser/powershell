function Get-NetworkToolsVersion{
    0.3101
}
 
function Get-ExternalIP{
    <#
        .SYNOPSIS
        Retrieves external IP of the connected network from wtfismyip.com
    #>
    $address = (((Invoke-WebRequest wtfismyip.com/text -UseBasicParsing).Content).TrimEnd())
    return New-Object PSObject -Property @{
        'IPAddress' = $address
    }
}
 
function Time-NSLookups{
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
            Resolve-DNSName -name $address -server $s -type A | Out-Null
            $elapsed = ((Get-Date) - $start).milliseconds
            $theArray += New-Object PSObject -Property @{
                'Server' = $s
                'Response' = $elapsed
                'Time' = $start
            }
        }
        Write-Progress -Activity "Testing Response Times" -PercentComplete (($i/$queries)*100)
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
 
    return $output
}
 
function Update-NetworkTools{
	(Invoke-WebRequest (Invoke-WebRequest https://www.plx-networks.com/powershell/NetworkTools/latest/index.txt -UseBasicParsing).content.trim() -UseBasicParsing).content | Out-File (Get-Module NetworkTools).path
        Write-Host "NetworkTools has been updated. To use the new version run Import-Module NetworkTools -force."
}
 
function Get-NetworkHosts{
    <#
        .SYNOPSIS
        Scans a subnet for reachable hosts
   
        .PARAMETER IPAddress
        Address in the subnet you wish to scan
   
        .PARAMETER NetworkBits
        Number of bits in the network
   
        .PARAMETER SubnetMask
        Subnet mask of the network
       
        .PARAMETER Timeout
        Timeout for ping requests. Defaults to 500ms
    #>
 
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$IPAddress,
        [Parameter(ParameterSetName='Mask',Mandatory=$true,Position=1)]
        [string]$SubnetMask,
        [Parameter(ParameterSetName='Bits',Mandatory=$true,Position=1)]
        [int]$NetworkBits,
        [Parameter(Mandatory=$false,Position=2)]
        [int]$Timeout = 500
    )
 
    function toBinary($dottedDecimal){
        $dottedDecimal.split(".") | %{$binary=$binary + $([convert]::toString($_,2).padleft(8,"0"))}
        return $binary
    }
 
    function toDottedDecimal ($binary){
        $i = 0
        do {$dottedDecimal += "." + [string]$([convert]::toInt32($binary.substring($i,8),2)); $i+=8 } while ($i -le 24)
        return $dottedDecimal.substring(1)
    }
 
    If($SubnetMask){
        $bnSubnet = toBinary($SubnetMask)
        $NetworkBits = $bnSubnet.IndexOf("0")
    }
    $bnAddress = toBinary($IPAddress)
    $StaticBits = $bnAddress.substring(0,$NetworkBits)
 
    $CurrentAddress = 1
    $LastAddress = "0".padleft(32-$NetworkBits,"1")
    $Addresses = @()
    $i = 0
    While($CurrentAddress -le ([Convert]::ToInt32($LastAddress,2))){
        $wrkAddress = [Convert]::ToString($CurrentAddress,2).padleft(32-$NetworkBits,"0")
        $wrkAddress = -join($StaticBits,$wrkAddress)
        $wrkAddress = toDottedDecimal($wrkAddress)
        If( (Get-WmiObject Win32_PingStatus -Filter "Address='$wrkAddress' and Timeout=$Timeout").ReplySize -ne $null ){
            $Addresses += New-Object PSObject -Property @{
                'IPAddress' = $wrkAddress
                'Up' = $true
            }
        }Else{
            $Addresses += New-Object PSObject -Property @{
                'IPAddress' = $wrkAddress
                'Up' = $false
            }
        }
        Write-Progress -Activity "Finding Hosts" -PercentComplete ($CurrentAddress/([Convert]::toInt32($LastAddress,2))*100)
        $CurrentAddress = $CurrentAddress + 1
        $i = $i + 1
        $wrkAddress = ""
    }
    return $Addresses
}
 
function Resolve-HostName{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
 
    $address = [string][System.Net.DNS]::GetHostByName($ComputerName).AddressList[0]
 
    return New-Object PSObject -Property @{
        'IPAddress' = $address
    }
}
 
function Test-NetworkPort{
	<#
		.SYNOPSIS
		Checks for open TCP ports
		
		.PARAMETER IPAddress
		IP address(es) to test

		.PARAMETER Port
		Port(s) to test
		
		.PARAMETER Timeout
		Time in milliseconds to wait for teh port to connect
	#>
	
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
		[string[]]$IPAddress,
		[Parameter(Mandatory=$true,Position=1)]
		[int[]]$Port,
		[Parameter(Mandatory=$false,Position=2)]
		[int]$Timeout = 250
	)
	
	$theArray = @()
	ForEach($a in $IPAddress){
		$socket = @()
		$i = 0
		ForEach($p in $Port){
			$socket+=New-Object System.Net.Sockets.TcpClient
			Write-Progress -Activity "Scanning port $p @ $a" -PercentComplete (($i/$port.length)*100)
			If($socket[$i].ConnectAsync($a,$p).Wait($timeout)){
				$theArray += New-Object PSObject -Propert @{
					'IPAddress' = $a
					'Port' = $p
				}
				$socket[$i].close()
			}
			$i++
		}
	}
	$theArray
}
 
If((Get-WmiObject Win32_OperatingSystem).Name -Like "*7*"){
    Export-ModuleMember Resolve-HostName
    Export-ModuleMember Get-NetworkHosts
    Export-ModuleMember Update-NetworkTools
    Export-ModuleMember Get-NetworkToolsVersion
	Export-ModuleMember Test-NetworkPort
	Export-ModuleMember Get-ExternalIP
}Else{
    Export-ModuleMember Get-NetworkHosts
    Export-ModuleMember Update-NetworkTools
    Export-ModuleMember Get-NetworkToolsVersion
    Export-ModuleMember Time-NSLookups
	Export-ModuleMember Test-NetworkPort
	Export-ModuleMember Get-ExternalIP
}
