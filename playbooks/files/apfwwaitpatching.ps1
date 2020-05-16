<#
	.SYNOPSIS
		This patching file is used to run on the host. This file will process the files given to it and look for the patch status that it has been given
	
	.DESCRIPTION
		This has the logic to check over files that have been gathered by the Ansible playbook.
	
	.PARAMETER hours
		This is the hours that the script has been allowed to run in hours before the script will time out.
	
	.PARAMETER job
		A description of the job parameter.
	
	.PARAMETER wait
		This is the wait time of the script before it starts at the beginning of the loop.
	
	.PARAMETER inventory
		A description of the inventory parameter.
	
	.PARAMETER toweruser
		A description of the toweruser parameter.
	
	.PARAMETER towerpwd
		A description of the towerpwd parameter.
	
	.PARAMETER towerservername
		A description of the towerservername parameter.
	
	.PARAMETER towercredential
		A description of the towercredential parameter.
	
	.PARAMETER tower
		A description of the tower parameter.
	
	.PARAMETER job_name
		This is the job name that has been supplied in the playbook.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.159
		Created on:   	5/03/2019 3:10 PM
		Created by:   	weiyentan
		Organization:
		Filename: apfwwaitpatchingscript.ps1
		Version: 0.2
		===========================================================================
#>
[CmdletBinding()]
param
(
	[int]$hours,
	[Parameter(Mandatory = $true)]
	[string]$job,
	[int]$wait,
	[string]$inventory,
	[string]$toweruser,
	[string]$towerpwd,
	[string]$towerservername,
	[string]$towercredential
)
$ErrorActionPreference = 'Stop'
#region define variables 
[System.Collections.ArrayList]$failedcollection = @()
$finalwaittime = (get-Date).AddHours($hours)
$fullpath = $PSScriptRoot
$stopwatch = [system.diagnostics.stopwatch]::StartNew()
$failtime = $false
$dateformat = (get-date -UFormat %d%m%y)
$string1 = "$fullpath/apfw_$job"
$string2 = "_$dateformat.log"
$logpath = $string1 , $string2 -join ""
Write-output $logpath
[System.Collections.ArrayList]$collection = @()
#endregion

#region define helper functions 
function Invoke-Towercliflow
{
	[CmdletBinding()]
	param
	(
		[Parameter(Position = 0)]
		[string]$limit,
		[string]$tower,
		[string]$job,
		[string]$inventory,
		[string]$credential
	)
	
	tower-cli job launch -J "APFW - Helper playbook" --wait --inventory $inventory --credential $towercredential --limit "$limit , localhost, $tower" -e "job_name=$job awx_host=$tower" | Out-Null
}

function Connect-Towercli
{
<#
	.SYNOPSIS
		Login to Tower Cli
	
	.DESCRIPTION
		A detailed description of the Login-Towercli function.
	
	.PARAMETER toweruser
		A description of the toweruser parameter.
	
	.PARAMETER towerpwd
		A description of the towerpwd parameter.
	
	.PARAMETER towerhost
		A description of the towerhost parameter.
	
	.EXAMPLE
		PS C:\> Login-Towercli
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]$toweruser,
		[string]$towerpwd,
		[string]$towerhost
	)
#	tower-cli config host $towerhost don't use this because it will mess with the hostname of tower
	tower-cli login $toweruser --password $towerpwd | Out-Null
}

#endregion
#region main script

Connect-Towercli -toweruser $toweruser -towerpwd $towerpwd 
"[Wait Patch Monitoring]" | Out-File -FilePath $logpath -Append
$servers = Get-content "$PSScriptRoot/collection_$job.txt" | Select-String -NotMatch "#" | select-object -Unique | Select-String -NotMatch localhost
"[$(Get-Date)][$($env:HOSTNAME)][Reading Collection objects from $PSScriptRoot/collection_$job.txt]" | Out-File -FilePath $logpath -Append
foreach ($server in $servers)
{
	$collection.Add($server) | out-null
	Write-Output "adding $server to collection to evaluate"
	"[$(Get-Date)][$($env:HOSTNAME)][Adding $server to collection ]" | Out-File -FilePath $logpath -Append
}





do #region action to take in looping through servers. 
{
	$dateformat = (get-date -UFormat %d%m%y)
	$string2 = "_$dateformat.log"
	$logpath = $string1 , $string2 -join ""

	$timeduration = New-TimeSpan -Start (Get-date) -End (get-date $finalwaittime)
	if ($Timeduration.minutes -le 0 -and $Timeduration.hours -le 0) #This is to make sure that the hours and minutes fit the consistency. Minutes could be 0 when it has 2 hours left. ie 2 hours 0 minutes
	{
		$failtime = $true
		"[$(Get-Date)][$($env:HOSTNAME)][Time of  (get-date $finalwaittime) has been exceeded. Exiting loop  ]" | Out-File -FilePath $logpath -Append
		break
	}
	Invoke-Towercliflow -limit ($collection -join '', ',') -tower $towerservername -Verbose -job $job -inventory $inventory -credential $towercredential  #Retrieving Patching status through Tower-Cli
	
	write-output "Fullpath variable is $fullpath"
	"[$(Get-Date)][$($env:HOSTNAME)][Fullpath variable is $fullpath ]" | Out-File -FilePath $logpath -Append
	
	"[$(Get-Date)][$($env:HOSTNAME)][Gathering patching status from collection ]" | Out-File -FilePath $logpath -Append
	foreach ($server in $servers)
	{
		if ($collection -contains $server)
		{
			#Invoke-Towercliflow -limit $server -tower $tower -Verbose -job $job
			"[$(Get-Date)][Processing server $server]" | Out-File -FilePath $logpath -Append
			Write-output "Processing $server"
			"[$(Get-Date)][Fullname is $fullpath]" | Out-File -FilePath $logpath -Append
			Write-Output " Fullname is $fullpath"
			$serverstatuspath = get-childitem $fullpath | Where-Object {$_.basename -like "*$server*" -and $_.Extension -like "*xml"}  | Select-Object -ExpandProperty fullname
			"[$(Get-Date)][Server path is $serverstatuspath ]" | Out-File -FilePath $logpath -Append
			Write-Output "serverstatuspath is $serverstatuspath"
			if ($serverstatuspath)
			{
				$testfile = Test-Path $serverstatuspath
				Write-Output "Testing if the patching status file for $server exists"
				"[$(Get-Date)][$($env:HOSTNAME)][Testing if the patching status file for $server exists ]" | Out-File -FilePath $logpath -Append
				
				if ($testfile)
				{
					$status = Import-Clixml $serverstatuspath
					"[$(Get-Date)][$($($env:HOSTNAME))][Importing in $serverstatuspath ]" | Out-File -FilePath $logpath -Append
					
					if ($status.PatchingProgress -eq 'success')
					{
						"[$(Get-Date)][$($($env:HOSTNAME))][Computer has patched. Removing $server from Collection ]" | Out-File -FilePath $logpath -Append
						Write-Output " Computer has patched. Removing $server from Collection"
						$collection.Remove($server)
						
					}
					elseif ($status.PatchingProgress -eq 'inprogress')
					{
						"[$(Get-Date)][$($($env:HOSTNAME))][$server has not been removed because the patching is still in progress .]" | Out-File -FilePath "$fullpath/apfw_$job_$dateformat.txt" -Append
						Write-Output " $server has not been removed because the patching is still in progress ."
					}
					
					elseif ($status.PatchingProgress -eq 'failed')
					{
						"[$(Get-Date)][$($($env:HOSTNAME))][The patching has failed for $server . Adding to failed collection]" | Out-File -FilePath $logpath -Append
						
						write-output "The patching has failed for $server . Adding to failed collection"
						$collection.Remove($server)
						$failedcollection.add($server)
					}
				}
				elseif (!$testfile)
				{
					"[$(Get-Date)][$($env:HOSTNAME)][$server patching status cannot be determined at this moment. The patching status has not been retrieved from this computer. This could be because the patching definition file has not been generated , the patching has not started or the server $server been rebooted ]" | Out-File -FilePath $logpath -Append
					write-output "$server patching status cannot be determined at this moment. The patching status has not been retrieved from this computer. This could be because the patching definition file has not been generated , the patching has not started or the server $server been rebooted."
				}
			}
			
		}
		else
		{
			Write-Output "collection number contains $collection"
			
		}
		
		
		
		
	}
	
	if ($collection.Count -eq 0)
	{
		"[$(Get-Date)][$($env:HOSTNAME)][All servers is fully patched. Exiting loop.  ]" | Out-File -FilePath $logpath -Append
		Write-Output "All servers is fully patched. Exiting loop."
		Break
		
	}
	if ($failedcollection.count -gt 0)
	{
		Write-Output $failedcollection
		foreach ($item in $failedcollection)
		{
			"[$(Get-Date)][$($env:HOSTNAME)][The computer $item has a failed patching status. Please investigate.    ]" | Out-File -FilePath $logpath -Append
			Write-Output "The computer $item has a failed patching status. Please investigate. "
			
		}
	}
	
	$filecount = Get-ChildItem $fullpath
	Write-Output "File path $fullpath has $($filecount.Count)"
	"[$(Get-Date)][$($env:HOSTNAME)][File path $fullpath has $($filecount.Count) ]" | Out-File -FilePath $logpath -Append
	
	Write-Output "Sleeping for $wait minutes"
	[int]$min = [int]$($wait * 60)
	"[$(Get-Date)][$($env:HOSTNAME)][sleeping for $min minutes]" | Out-File -FilePath $logpath -Append
	Start-Sleep -Seconds $min
	
}
until ($collection.Count -eq 0)

$stopwatch.Stop()

Write-Output "The time taken is $($stopwatch.elapsed)"
if ($failtime)
{
	"[$(Get-Date)][$($env:HOSTNAME)][The time taken for the Patching job $job has exceeded and therefore the process has failed.   ]" | Out-File -FilePath $logpath -Append
	throw "The time taken for the Patching job $job has exceeded and therefore the process has failed.  "
	
}
elseif ($failedcollection)
{
	"[$(Get-Date)][$($env:HOSTNAME)][There are servers that have failed patches   ]" | Out-File -FilePath $logpath -Append
	foreach ($item in $failedcollection)
	{
		"[$(Get-Date)][$($env:HOSTNAME)][The computer $item has a failed patching status   ]" | Out-File -FilePath $logpath -Append
		Write-output "[$(Get-Date)][$($env:HOSTNAME)][The computer $item has a failed patching status ]"
	}
	$failedcollection | Out-File -FilePath $logpath -Append
	throw "There are servers that have failed to install patches."
	
}
else
{
	"[$(Get-Date)][$($env:HOSTNAME)][All computers in the job $job have been patched Patching is complete   ]" | Out-File -FilePath $logpath -Append
	
	Write-Output "All computers in the job $job have been patched Patching is complete."
}
#endregion
#endregion
