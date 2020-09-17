#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

# Check if EKS deployment, set kubectl environment and EKS deployment options in local.env
if [[ -e "eks-scripts/cluster-config.sh" ]]; then source eks-scripts/cluster-config.sh; fi
if [[ -e "local.env" ]]; then source local.env; fi

exec 3>&1

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function setup() {
  ingressip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  ingressport=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
   
  _out ------------------------------------------------------------------------------------
  
  _out articles
  nodeport=$(kubectl get svc articles --ignore-not-found --output 'jsonpath={.spec.ports[*].nodePort}')
  if [ -z "$nodeport" ]; then
    _out articles is not available. Run 'scripts/deploy-articles-java-jee.sh'
  else 
    _out API explorer: http://${ingressip}:${ingressport}/openapi/ui/
    _out Sample API: curl \"http://${ingressip}:${ingressport}/web-api/v1/getmultiple?amount=10\"
  fi
  _out ------------------------------------------------------------------------------------

  _out authors
  nodeport=$(kubectl get svc authors --ignore-not-found --output 'jsonpath={.spec.ports[*].nodePort}')
  if [ -z "$nodeport" ]; then
    _out authors is not available. Run 'scripts/deploy-authors-nodejs.sh'
  else 
    _out Sample API: curl \"http://${ingressip}:${ingressport}/api/v1/getauthor?name=Niklas%20Heidloff\"
  fi
  _out ------------------------------------------------------------------------------------
  
  _out web-api
  nodeport=$(kubectl get svc web-api --ignore-not-found --output 'jsonpath={.spec.ports[*].nodePort}')
  if [ -z "$nodeport" ]; then
    _out web-api is not available. Run 'scripts/deploy-web-api-java-jee.sh'
  else 
    _out API explorer: http://${ingressip}:${ingressport}/openapi/ui/
    _out Sample API: curl \"http://${ingressip}:${ingressport}/web-api/v1/getmultiple\"
  fi
  _out ------------------------------------------------------------------------------------
  
  _out web-app
  nodeport=$(kubectl get svc web-app --ignore-not-found --output 'jsonpath={.spec.ports[*].nodePort}')
  if [ -z "$nodeport" ]; then
    _out web-app is not available. Run 'scripts/deploy-web-app-vuejs.sh'
  else 
    ingress=$(kubectl get gateway --ignore-not-found default-gateway-ingress-http --output 'jsonpath={.spec}')
    if [ -z "$ingress" ]; then
      _out Ingress not available. Run 'scripts/deploy-istio-ingress-v1.sh'
    else
      _out Web app: http://${ingressip}:${ingressport}/
    fi
  fi
  _out ------------------------------------------------------------------------------------

}

setup
