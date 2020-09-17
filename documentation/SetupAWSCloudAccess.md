## Access AWS Cloud

In order to use services from the AWS Cloud like the Amazon Elastic Kubernetes Service, follow these instructions.

First get an [AWS Cloud account](https://portal.aws.amazon.com/billing/signup#/start). It's free, there is no time restriction and no credit card is required!

**Get the code**

```
$ git clone https://github.com/dleecn/cloud-native-starter.git
$ cd cloud-native-starter
```

**Prerequisites**

Make sure you have the following prerequisites installed:

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 
* [curl](https://curl.haxx.se/download.html)
* [aws CLI](https://aws.amazon.com/cli/)
* [eksctl CLI](https://eksctl.io/)

Run this script to check the prerequisites:

```
$ aws-scripts/check-prerequisites.sh
```

**Create an API Key**

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