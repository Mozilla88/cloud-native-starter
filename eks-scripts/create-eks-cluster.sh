#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function _err() {
  echo "$@" >&4
  echo "$(date +'%F %H:%M:%S') $@"
}

readonly CFG_FILE=${root_folder}/local.env
# Check if config file exists, in this case it will have been modified
if [ ! -f $CFG_FILE ]; then
     _out Config file local.env is missing!
     _out -- Copy template.local.env to local.env and edit according to our instructions!
     exit 1
fi  

# SETUP logging (redirect stdout and stderr to a log file)
readonly LOG_FILE=${root_folder}/eks-scripts/create-eks-cluster.log 
touch $LOG_FILE


function create_cluster() {
  _out Creating Lite Kubernetes Cluster on AWS Cloud

  source $CFG_FILE
  _out Logging into AWS Cloud
  aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID >> $LOG_FILE 2>&1
  aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY >> $LOG_FILE 2>&1
  aws configure set default.region $AWS_REGION >> $LOG_FILE 2>&1
  aws configure set default.output $AWS_OUTPUT >> $LOG_FILE 2>&1

  _out Creating cluster
  eksctl create cluster --name cloud-native --nodes=2 --ssh-access --ssh-public-key "~/.ssh/id_rsa.pub" >> $LOG_FILE 2>&1
  # check if something went wrong
   if [ $? == 0 ]; then 
     _out -- Creating a cluster will take some time, please wait at least 20 minutes before
     _out -- executing the next script eks-scripts/cluster-get-config.sh
     _out ---- cluster-get-config.sh will check if the cluster is ready
   else
     _out SOMETHING WENT WRONG! Check the eks-scripts/create-eks-cluster.log
   fi
}

create_cluster
