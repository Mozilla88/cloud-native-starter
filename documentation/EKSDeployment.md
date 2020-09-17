## Deployment on AWS Cloud using Amazon Elastic Kubernetes Service

If you want to deploy the Cloud Native Starter on Amazon Elastic Kubernetes Service (EKS), the AWS managed Kubernetes offering, then follow these steps. They will create a Kubernetes Cluster with Istio enabled and a namespace in the Amazon Elastic Container Registry (ECR) where the container images of the microservices will be created, stored, and made available for Kubernetes deployments. By default, deployment is in Hong Kong, China (ap-east-1). If you already have a cluster in Hong Kong, these scripts will not work because only one cluster is allowed. 

### Get the code:

```
$ git clone https://github.com/dleecn/cloud-native-starter.git
$ cd cloud-native-starter
```
### Prerequisites:
Most important: an AWS Cloud account, you can register for a free account [here](https://portal.aws.amazon.com/billing/signup#/start).

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 
* [curl](https://curl.haxx.se/download.html)
* [docker](https://docs.docker.com/install/) requires not only the code but also permission to run docker commands
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [aws CLI](https://aws.amazon.com/cli/)
* [eksctl CLI](https://eksctl.io/)

A really nice feature of Amazon EKS clusters is that they use your AWS IAM users and groups for authentication, rather than the cluster having a separate set of users (as you’re probably accustomed to). Although the authentication is different, authorization uses the same RBAC system – you’re just binding your existing AWS Identity and Access Management (IAM) users to Roles instead of Kubernetes-internal users.

For this authentication to work, your kubectl needs to be able to present your AWS credentials to the cluster, rather than the Kubernetes-specific x509 certificate you probably use now.

To do that, kubectl needs a plugin:

```
go get -u -v github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
```

Run this script to check the prerequisites:

```
$ eks-scripts/check-prerequisites.sh
```

### To prepare the deployment on AWS Cloud:

This creates an API key for the scripts.

```
$ aws iam create-access-key > cloud-native-starter.json
$ cat cloud-native-starter.json
$ cp template.local.env local.env 
```

From the output of `cloud-native-starter.json` copy the AccessKeyId without " " into AWS_ACCESS_KEY_ID= and copy the SecretAccessKey without " " into AWS_SECRET_ACCESS_KEY= in file local.env.

The file local.env has preset values for region and image registry namespace in local.env. You can change them of course if you know what you are doing.

Example local.env:

```
AWS_ACCESS_KEY_ID=AKIAIEPWMPY2VARCISCA
AWS_SECRET_ACCESS_KEY=epaeO8RjpehEOn6DByjgJTz3mA8ZvDpjVKM7M2rx
AWS_REGION=ap-east-1
AWS_OUTPUT=json
REGISTRY=836946026989.dkr.ecr.ap-east-1.amazonaws.com
REGISTRY_NAMESPACE=cloud-native
AUTHORS_DB=local
CLOUDANT_URL=
```

### Create Amazon Elastic Kubernetes Service Environment

This step creates a Kubernetes cluster on AWS Cloud. 

```
$ eks-scripts/create-eks-cluster.sh
```

Creating a cluster takes some time, typically at least 20 minutes.

The next command checks if the cluster is ready and if it is ready. If the cluster isn't ready, the script will tell you. Then just wait a few more minutes and try again.

```
$ eks-scripts/cluster-get-config.sh
```

**NOTE:** You **MUST** run this command to check for completion of the cluster provisioning and it must report that the cluster is ready for Istio installation! 

From now on if you want to use `kubectl` commands with your EKS cluster and you have used other Kubernetes environments before, e.g. Minikube, use this command (`cluster-get-config.sh`) to get access to the EKS cluster again. 

### Add Istio

Amazon Elastic Kubernetes Service has an option to install a managed Istio into a Kubernetes cluster. Unfortunately, the Kubernetes Cluster we created in the previous step does not meet the hardware requirements for managed Istio. Hence we do a manual install of the Istio demo or evaluation version.

These are the instructions to install Istio. We used and tested Istio 1.5.1 for this project. Please be aware that these installation instructions will not work with Istio versions prior to 1.4.0!


1. Download Istio, this will create a directory istio-1.5.1:

    ```
    curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.5.1 sh -
    ```

1. Add `istioctl` to the PATH environment variable, e.g copy paste in your shell and/or `~/.profile`. Follow the instructions in the installer message.


    ```
    export PATH="$PATH:/path/to/istio-1.5.1/bin"
    ```

1. Verify the `istioctl` installation:


    ```
    $ istioctl version 
    ```

1. Install Istio on the Kubernetes cluster:

    We will use the `demo` profile to install Istio. 

    **Note:** This is a "...configuration designed to showcase Istio functionality with modest resource requirements. ... **This profile enables high levels of tracing and access logging so it is not suitable for performance tests!**"

    ```
    $ istioctl manifest apply --set profile=demo
    ```


1. Check that all pods are running before continuing.
  
    ```
    $ kubectl get pod -n istio-system
    ```

1. Verify Istio installation

    This generates a manifest file for the demo profile we used to install Istion and then verifies the installation against this profile.

    ```
    $ istioctl manifest generate --set profile=demo > generated-manifest.yaml
    $ istioctl verify-install -f generated-manifest.yaml
    ```

    Result of the second command (last 3 lines) looks like this:

     ```
     Checked 25 crds
	 Checked 3 Istio Deployments
	 Istio is installed successfully
	 ```
 
1. Enable automatic sidecar injection for `default`namespace:

    ```
    $ kubectl label namespace default istio-injection=enabled
    ```

Once complete, the Kiali dashboard can be accessed with this command:

```
$ istioctl dashboard kiali
```

Log in with Username: admin, Password: admin

### Create Container Registry

When Istio is installed and all Istio pods are started, create a namespace in the AWS Cloud Container Registry:

```
$ eks-scripts/create-registry.sh
```

The container images we will build next are stored in the Container Registry as `{aws_account_id}.dkr.ecr.{region}.amazonaws.com/cloud-native/<imagename>:<tag>` if you didn't change the defaults.


### Initial Deployment of Cloud Native Starter

To deploy (or redeploy) run these scripts:

```
$ eks-scripts/deploy-articles-java-jee.sh
$ eks-scripts/deploy-web-api-java-jee.sh
$ eks-scripts/deploy-authors-nodejs.sh
$ eks-scripts/deploy-web-app-vuejs.sh
$ scripts/deploy-istio-ingress-v1.sh
$ eks-scripts/show-urls.sh
```

After running all (!) the scripts above, you will get a list of all URLs in the terminal. 

<kbd><img src="../images/EKS-urls.png" /></kbd>

### Demo Traffic Routing

Run these scripts to deploy version 2 of the web-api and then apply Istio traffic routing to send 80% of the traffic to version 1, 20% to version 2:

```
$ eks-scripts/deploy-web-api-java-jee-v2.sh
$ scripts/deploy-istio-ingress-v1-v2.sh
``` 

Create some load and view the traffic distribution in the Kiali console.

### Cleanup

Run the following command to delete all cloud-native-starter components from EKS:

```
$ scripts/delete-all.sh
```

You can also delete single components:

```
$ scripts/delete-articles-java-jee.sh
$ scripts/delete-articles-java-jee-quarkus.sh
$ scripts/delete-web-api-java-jee.sh
$ scripts/delete-authors-nodejs.sh
$ scripts/delete-web-app-vuejs.sh
$ scripts/delete-istio-ingress.sh
```


