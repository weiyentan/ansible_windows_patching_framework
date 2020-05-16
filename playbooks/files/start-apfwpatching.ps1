[CmdletBinding()]
param
(
	[string]$limit,
	[string]$duration,
	[string]$wait = '5',
	[int]$apfw_waittime = '10',
	[string]$jobtemplate = 'APFW  - WSUS Patching Template',
	[Parameter(Mandatory = $true)]
	[string]$inventory,
	[string]$towerusername,
	[string]$towerpwd,
	[string]$towercredential
)


$date = Get-Date
$futuredate = get-date ($date.AddHours($duration)) -UFormat %d/%m/%Y
$futuretime = get-date ($date.AddHours($duration)) -Format H:mm
sudo tower-cli login $towerusername --password $towerpwd | out-null
$job = sudo tower-cli job launch -J $jobtemplate --format json --limit $limit --credential $towercredential --inventory $inventory -e "apfw_enddate=$futuredate apfw_endtime=$futuretime apfw_waittime=$apfw_waittime"
[int]$jobidoutput =$job | ConvertFrom-Json  | Select-Object -ExpandProperty id
write-output $jobidoutput
	