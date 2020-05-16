[CmdletBinding()]
param
(
	[string]$limit,
	[string]$managementserver,
	[string]$searchterm,
	[Parameter(Mandatory = $true)]
	[string]$inventory,
	[string]$towerusername,
	[string]$towerpwd,
	[string]$towercredential,
	[string]$towerservername,
	[string]$archivesetting,
	[string]$towerjobcredential,
	[string]$destinationlogpath
)



sudo tower-cli login $towerusername --password $towerpwd | Out-Null
$job = sudo tower-cli job launch -J 'APFW - Helper playbook - Transfer archive to management host' --format json --limit "$limit , localhost, $towerservername" --credential $towercredential --inventory $inventory -e "management_server=$managementserver awx_host=$towerservername search_term=$searchterm  tower_jobcredential=$towerjobcredential destination_logpath='$destinationlogpath'"
[int]$jobid = $job | ConvertFrom-Json  | Select-Object -ExpandProperty id
$jobid	