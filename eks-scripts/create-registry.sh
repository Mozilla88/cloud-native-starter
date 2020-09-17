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

# SETUP logging (redirect stdout and stderr to a log file)
readonly LOG_FILE=${root_folder}/eks-scripts/create-registry.log 
touch $LOG_FILE

function create_registry() {
  _out Logging into AWS Cloud
  aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID >> $LOG_FILE 2>&1
  aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY >> $LOG_FILE 2>&1
  aws configure set default.region $AWS_REGION >> $LOG_FILE 2>&1
  aws configure set default.output $AWS_OUTPUT >> $LOG_FILE 2>&1

  _out Creating Repositories in Namespace $REGISTRY_NAMESPACE
  aws ecr create-repository --repository-name $REGISTRY_NAMESPACE/articles >> $LOG_FILE 2>&1
  aws ecr create-repository --repository-name $REGISTRY_NAMESPACE/web-api >> $LOG_FILE 2>&1
  aws ecr create-repository --repository-name $REGISTRY_NAMESPACE/authors >> $LOG_FILE 2>&1
  aws ecr create-repository --repository-name $REGISTRY_NAMESPACE/web-app >> $LOG_FILE 2>&1

  # check if something went wrong
  if [ $? == 0 ]; then 
    _out Namespace in Amazon Elastic Container Registry created
  else
    _out SOMETHING WENT WRONG! Check the eks-scripts/create-registry.log 
  fi
}

create_registry
