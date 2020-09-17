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
source $CFG_FILE


function test_cluster() {
  _out Check if Kubernetes Cluster is available ...
  STATUS=$(eksctl get cluster -n cloud-native | awk '/^cloud-native/ {print $3}')
  if [ $STATUS != "ACTIVE" ]; then 
    _out -- Your Kubernetes cluster is in $STATUS state and not ready
    _out ---- Please wait a few more minutes and then try this command again 
    exit 1
   else
    _out Retrieving eks cluster info for EKS cluster
    aws eks describe-cluster --name cloud-native
    _out -- Cluster cloud-native is ready for Istio installation
  fi
}

test_cluster

