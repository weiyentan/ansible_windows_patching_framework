# AnsiblePatchingFramework

This project provides a patching orchestration framework for Ansible in particular focus towards AWX / Tower.

This patching framework does not use the traditional winupate ansible module which is part of ansible core modules. The reason behind that is because of the way that ansible works is the use of forks. Ansible has a default number of forks of 5. Forks determine how many parallel tasks can be performed on a device at a time. For short tasks ( that make take minutes to conplete) this works fine on a large number of hosts (example 100+ hosts ). However this can cause problems  when the tasks can take a long time. This can be apparent when patching windows computers like Windows Server 2016 which can take  up to 45 minutes or more. While the number of forks can be increased to accomodate the number of hosts this can increase the instability of the task as Ansible now has to keep track of all the computers mentioned. This can also increase the  resources needed. Referring to Ansible documentation on 
https://docs.ansible.com/ansible-tower/3.6.2/html/userguide/jobs.html#ug-job-concurrency:

To calculate how  many forks can be used they came up with this algorithm (default is 100 MB per fork):
```
(mem - 2048) / mem_per_fork
```

Therefore a 4 GB machine can handle 20 forks on the Ansible controller. 
```
(4096 - 2048) / 100 == ~20
```

In terms of CPU,  the documentation refers to this requirement (with a requirement of 4 forks per core):
```
cpus * fork_per_cpu
```
Which means that a 4 core system requires:

```
4 * 4 == 16
```

If we are patching 200 odd Windows computers using the traditional winupdates  we are faced with two scenarios:

1. Use the default forks. In which case we have 200 odd computers with the default of 5 Forks. What will happen is that Ansible will take the first  5 computers, start the patching process which will take 45 minutes then move onto the next 5. To patch 200 computers will take 30 hours to complete.

2. Increase the number of forks to match the number of computers. This would  mean that the specification of the server would amount to:
   (x - 2048) / 100 == ~200 (22GB memory) , x * 4 == 200 (50 cores)
   Obviously this is not ideal.

This project uses a  custom role that seeks to remedy this problem for the likes of Windows Patching: install-winupdate.

What makes this different? Instead of attempting to patch the destination computer it attempts to configure the machine with the right setting so that a custom patching script will run locally and start the patching. Ansible is essentially acting as a configuration management tool and then orchestrates . Once configuration is done and the scheduled task is started , Ansible moves onto the next block of forks.

The configuration is quick and because it is not waiting for servers to complete patching within the role initiating the patching doesnt take long to complete.

This project playbooks takes care of pretasks/posttasks and in cases where you want to wait for a certain number of computers to patch then move onto another it has a script in place to handle this.


## Prerequisites
This project requires PowerShell 6.2+ installed on the linux host of AWX, as some of the scripts are written in PowerShell.

This project also relies on tower-cli and a tower-cli config config file for the user logging in to the AWX host from Ansible.



## Vars
There are a number of vars used in a  job template  that runs this playbook:
```
awx_host
inventory
PatchGroup1
PatchGroup2
PatchGroup3
apfw_duration1
apfw_duration2
apfw_duration3
destination_logpath
apfw_wait
credential_name
job_name1
job_name2
job_name3
management_server
mode
monitoring_downtime_duration_secs_1
monitoring_downtime_duration_secs_2
monitoring_downtime_reason
monitoring_server
monitoring_suppression_on
posttasks_1
posttasks_2
posttasks_3
pretasks_1
pretasks_2
posttasks_common
waithours1
waithours2
waithours3
waittime
```

## awx_host:
This is the awx host

## inventory
This is the inventory that is being targeted to patch.

## PatchGroup 1-3
These are the groups that are being patched. There are three playbooks each ranging from 1 patchgroups to 3.

## apfw_duration (Patchgroup 1-3)
This is the duration (in hours) that the patching process is given.

## destination_logpath
During the patching process the framework will copy all logs to a directory on a windows server (ths can be a management server). The format for the path is for example e:/patch_log/Jobname
The reasoning behind this is that linux gets confused with \ being used.






# TODO
~~* Windows Powershell scripts need to be written (or existing scripts need to be modified so that it is crossplatform) At the moment the structure is written for Linux.~~ This is not needed as this is now consolidated into plays.

* ~~Yet to be decided whether or not in the wait script the retrieval of files should be individual server. At the time was used for troubleshooting but because ansible has a default fork of 5 it might seem better to handle it that way.~~ This has been done and now the helper playbook refers to the collection as a pose to individual nodes.
  
~~* Playbook needs to be written that uses the  tower-cli module to generate these templates in Ansible Tower/AWX so it  can be recreated.~~ Generic templates have been created and there are deployment playbooks that will deploy that to the Ansible tower. 

