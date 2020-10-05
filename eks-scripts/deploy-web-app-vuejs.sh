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

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function configureVUEminikubeIP(){
  cd ${root_folder}/web-app-vuejs/src
  
  _out configure API endpoint in web-app
  clusterip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  ingressport=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

  rm "store.js"
  # cp "store.js.template" "store.js"
  sed -e "s/endpoint-api-ip/$clusterip/g" -e "s/ingress-np/${ingressport}/g" store.js.template > store.js
  
  cd ${root_folder}/web-app-vuejs
}

function setup() {
  _out Deploying web-app-vuejs
  
  cd ${root_folder}/web-app-vuejs
  kubectl delete -f deployment/kubernetes.yaml --ignore-not-found
  kubectl delete -f deployment/istio.yaml --ignore-not-found
  
  configureVUEminikubeIP

  # docker build replacement for ECR
  docker build -f Dockerfile -t $REGISTRY/$REGISTRY_NAMESPACE/web-app:1 .
  docker push $REGISTRY/$REGISTRY_NAMESPACE/web-app:1

  # Add ECR tags to K8s deployment.yaml  
  sed "s+web-app:1+$REGISTRY/$REGISTRY_NAMESPACE/web-app:1+g" deployment/kubernetes.yaml > deployment/EKS-kubernetes.yaml
  kubectl apply -f deployment/EKS-kubernetes.yaml
  kubectl apply -f deployment/istio.yaml

  cd ${root_folder}/web-app-vuejs/src
  cp "store.js.template" "store.js"

  _out Done deploying web-app-vuejs
  _out Wait until the pod has been startedCheck with these commands: 
  _out "kubectl get pod --watch | grep web-app"
}

#exection starts from here

#setupLog
setup
