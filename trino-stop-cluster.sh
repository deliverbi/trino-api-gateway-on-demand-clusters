# DELIVERBI Trino Cluster on Demand Script
# Shahed Munir , Krishna Udathu
# Production Date 26/09/2022

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


gcloud compute instances stop DELIVERBI-trino-master-$check_cluster_id --zone=europe-west2-c
gcloud compute instance-groups managed resize DELIVERBI-trino-worker-highmem16-397-highcpu-m$check_cluster_id --size 0 --project=DELIVERBI-platform --zone=europe-west2-c

sleep 1m
rm -f $log_path/m$check_cluster_id.running
echo "All Done Trino m$check_cluster_id is fully down"
