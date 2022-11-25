# DELIVERBI Trino Cluster on Demand Script
# Shahed Munir , Krishna Udathu
# Production Date 26/09/2022
#!/bin/bash

check_cluster_id=$1
num_workers=$2
log_path="/trinoapp/logs"

if [ -z "$1" ]
  then
    echo "Please supply cluster ID ie 1 or 2 etc"
    exit
    fi

if [ -z "$2" ]
  then
    echo "Please supply number of workers"
    exit
    fi

#Check if Cluster is already running.

if [ -e $log_path/m$check_cluster_id.running ]
then
echo "Trino M$check_cluster_id is already running so exiting"
exit 1
fi

gcloud compute instances start DELIVERBI-trino-master-$check_cluster_id --zone=europe-west2-c
sleep 1m
gcloud compute instance-groups managed resize DELIVERBI-trino-worker-highmem16-397-highcpu-m$check_cluster_id --size $num_workers --project=DELIVERBI-platform --zone=europe-west2-c




> $log_path/DELIVERBI-trino-master-$check_cluster_id-counter.out

gcloud compute instance-groups managed list-instances DELIVERBI-trino-worker-highmem16-397-highcpu-m$check_cluster_id --project=DELIVERBI-platform --zone=europe-west2-c --format='csv[no-heading](NAME)' > $log_path/DELIVERBI-trino-master-$check_cluster_id.out


while true
do

log_path="/trinoapp/logs"

> $log_path/DELIVERBI-trino-master-$check_cluster_id-counter.out

INPUTTAB=$log_path/DELIVERBI-trino-master-$check_cluster_id.out
OLDTABIFS=$IFS
IFS=,
[ ! -f $INPUTTAB ] && { echo "$INPUTTAB file not found"; exit 99; }
while read workername
do

v1=$workername
log_path="/trinoapp/logs"

isnodeactive=`curl -s http://$workername:8060/v1/info/state`
isnodeactive2=${isnodeactive:1:6}

#If response is null then shut it down as systemctl service has been shutdown completely
if [ $isnodeactive2 == "ACTIVE" ]
then echo "$v1 is active" >> $log_path/DELIVERBI-trino-master-$check_cluster_id-counter.out
fi

done < $INPUTTAB
IFS=$OLDTABIFS

if [ `cat $log_path/DELIVERBI-trino-master-$check_cluster_id-counter.out | wc -l` == "$num_workers" ]
then 
echo "All Done Trino M$check_cluster_id is fully up"
> $log_path/m$check_cluster_id.running
echo "ServerUP"
exit 0
fi

sleep 20s

done
