##Deprecated 
This readme is how the proof of concept worked previously.

The revised code works by using import_tasks and vars. The new readme can be found here.
# Core Templates
This is a list of main job templates that are used in AWX and this patch package. It will highlight the required extra-vars  and settings that are needed. These job templates uses a  backend script is a powershell script that calls ansible tower using tower-cli.


### apfw_patching_template
This is the 'wrapper' job template that calls a job template that has the apfw_enddate and apfw_endtime variables. By using this template users can just type in the duration of the job rather than the end date, end time and wait time of the patching job. The limit that you should be passing to the playbook is your awx host.
####variables
```
duration
limit
apfw_waittimemin
jobtemplate
job_name
```
* Duration relates to the hours that the wait patch will last.
* limit is what hosts you are going to target.
* apfw_waittimemin is the time that the monitor_patch scheduled task  will wait before it run through the internal loop again.  
* jobtemplate is the job template that you are calling.
* job_name is the name of the job

### apfw_wait_patch template
This is the playbook that waits for patches to finish on the inventory that is being targeted. It gathers the current inventory of the servers. The limit should be in this form  syntax: PatchGroup:AWXhost:localhost . Where AWXhost is the name of your AWX host.
#### variables
```
run_task: 'true'
job_name1: 'PatchGroup1'
awx_host: 'AWX'
apfw_wait_hours1: '3'
apfw_wait: '10'
```
* run_task determines whether the job will run 
* job_name1 determines the name of the job
* awx_host is the name of AWX host
* apfw_wait_hours1 is the duration (in hours how long the script will wait before failing the job.)
* apfw_wait is the wait time in minutes 