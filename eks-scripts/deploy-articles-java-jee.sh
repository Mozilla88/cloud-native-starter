#!/bin/bash 

root_folder=$(cd $(dirname $0); cd ..; pwd)

CFG_FILE=${root_folder}/local.env
# Check if config file exists
if [ ! -f $CFG_FILE ]; then
     _out Config file local.env is missing! Check our instructions!
     exit 1
fi  
source $CFG_FILE

# Login to Amazon Elastic Container Registry
# aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function setup() {
  _out Deploying articles-java-jee
  
  cd ${root_folder}/articles-java-jee
  kubectl delete -f deployment/kubernetes.yaml --ignore-not-found
  kubectl delete -f deployment/istio.yaml --ignore-not-found

  file="${root_folder}/articles-java-jee/liberty-opentracing-zipkintracer-1.3-sample.zip"
  if [ -f "$file" ]
  then
	  echo "$file found"
  else
	  curl -L -o $file https://github.com/WASdev/sample.opentracing.zipkintracer/releases/download/1.3/liberty-opentracing-zipkintracer-1.3-sample.zip
  fi
  unzip -o liberty-opentracing-zipkintracer-1.3-sample.zip -d liberty-opentracing-zipkintracer/
  
  # docker build replacement for ECR
  docker build -f Dockerfile.nojava -t $REGISTRY/$REGISTRY_NAMESPACE/articles:1 .
  docker push $REGISTRY/$REGISTRY_NAMESPACE/articles:1

  # Add ECR tags to K8s deployment.yaml  
  sed "s+articles:1+$REGISTRY/$REGISTRY_NAMESPACE/articles:1+g" deployment/kubernetes.yaml > deployment/EKS-kubernetes.yaml
  kubectl apply -f deployment/EKS-kubernetes.yaml
  kubectl apply -f deployment/istio.yaml

  _out Done deploying articles-java-jee
  _out Wait until the pod has been started. Check with these commands: 
  _out "kubectl get pod --watch | grep articles"
}

setup
