__Bugs and requests__: submit them through the project's issues tracker.<br>
[![Issues](https://img.shields.io/github/issues/robmaynardjr/SmartCheck-Terraform-Lab.svg)]( https://github.com/robmaynardjr/SmartCheck-Terraform-Lab/issues ) [![GitHub tag](https://img.shields.io/github/tag-date/robmaynardjr/SmartCheck-Terraform-Lab.svg)](https://github.com/robmaynardjr/SmartCheck-Terraform-Lab/tags/)




# **Deep Security SmartCheck Lab**

This repository contains a terraform template to deploy a Trend Micro Deep Security SmartCheck lab into AWS. This project is configured to be launched from MacOS.

The following resources are created:
- 1 AWS EKS Kubernetes control plane.
- 1 Autoscaling group of 3, t2.medium, Kubernetes worker nodes.
- 1 Deployment of Trend Micro Deep Security SmartCheck.

**An AWS account is required for this project to work.**

---
## **Prerequisite Software**

- Terraform 0.11.0
  - https://www.terraform.io/
- The following terraform providers will be installed when you initialize the project:
  - aws 1.56.0
  - null 2.0.0
- Python 3 or above
  - https://www.python.org/
- AWS CLI 1.16.18 or higher
  - https://docs.aws.amazon.com/cli/latest/userguide/installing.html
- Helm 2.8.0 or higher
  - https://docs.helm.sh/using_helm/#quickstart
- kubectl
  - https://kubernetes.io/docs/tasks/tools/install-kubectl/

---

## Config


### AWS Config

**NOTE: The AWS user (access/secret key) you use in the config.tf file needs to be the same one configured in AWS CLI**

Ensure that you set up an IAM user in AWS with a an Access and Security Key. See the following article for more info: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html


Follow the instructions at after installing AWS CLI:
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

You will need an existing VPC with at least 2 subnets in 2 different availability zones. You will also need to create a security group applied to that VPC with the following inbound rules configured:

![](/img/sgrules.jpg)


**Custom ICMP Rule: Protocol set to "Destination Unreachable" and port range field is set to "fragmentation required, and DF flag set"**

You will also need to configure a role with ability to create and manage the EKS Cluster. The role needs to be configured with the following roles:

- AmazonEKSServicePolicy
- AmazonEKSClusterPolicy

Make note of the ARN as it will be required in the config file.

The final AWS preperation item will be to ensure your VPC has a private key pair associated with it. Use the following documenation to create a new key-pair:

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

The key pair name will need to be identified in the config file.


### Setup Config File

The terraform file that builds the Kubernetes cluster uses variables that need to be defined in config.tf. Create a file in the repo root directory called 'config.tf'.

`touch config.tf`

Copy the below into config.tf. You will need to populate the variables by placing the value between the empty quotes. In the case where the variable is an AWS resource, it either requires an AWS resource ID or ARN if labeled as such, both of which can be found in your AWS console.

config.tf:
```
data "aws_availability_zones" "available" {}
variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "region" {
  default = ""
}

variable "create_role_arn" {
  default = ""
}

variable "vpcID" {
  default = ""
}

variable "subnet1" {
  default = ""
}

variable "subnet2" {
  default = ""
}

variable "eks-security-group" {
  default = ""
}

variable "vpcKey" {
  default = ""  
}
```

## Launch Template

Once all prep work is complete, run the following command from within the repo root folder:

`terraform init`

This will initialize the terraform project. 

`terraform plan`

If there is an error with any of the files, you will be alerted here. This will most likely be due to a null or misconfigured variable, so make sure to check config.tf if this portion errors out. The error message should point you in the right direction.

If the plan command goes through successfully, run:

`terraform plan -out=lab.tfplan`

This will run the plan operation again but this time output a plan file to apply.

Once you're ready to build your lab, run:

`terraform apply -auto-approve lab.tfplan`

The EKS build takes ~9 minutes on average, and the node deployment phase takes ~4 minutes on average, so be patient. Terraform will output the steps of the build. If any part errors, the terraform build will stop in place, so you may be left with half a lab. Running the build again after fixing the error will correct this. Once you are done with the EKS SmartCheck lab, run the following command to tear down the resources:

`terraform destroy`

The destroy process takes about the same amount of time as the build process.

## **EKS Control Plane pricing averages $5 a day! Make sure to `terraform destroy` when done!**

## SmartCheck Access

NOTES:

It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status of the load balancer by running:
<<<<<<< HEAD

     kubectl get svc --watch proxy

## 1. Get the application URL by running these commands:
###    Google Cloud or Azure:
      export SERVICE_IP=$(kubectl get svc proxy -o jsonpath={.status.loadBalancer.ingress[0].ip}')
###    AWS:
      export SERVICE_IP=$(kubectl get svc proxy -o jsonpath={.status.loadBalancer.ingress[0].hostname}')
      echo https://$SERVICE_IP:443

## 2. Get the initial administrator user name and password by running these commands:

      echo Username: $(kubectl get secrets -o jsonpath='{ .data.userName }' deepsecurity-smartcheck-auth | base64 --decode)
      echo Password: $(kubectl get secrets -o jsonpath='{ .data.password }deepsecurity-smartcheck-auth | base64 --decode)

=======
     ```
     kubectl get svc --watch proxy
     ```
## 1. Get the application URL by running these commands:
###    Google Cloud or Azure:
      ```
      export SERVICE_IP=$(kubectl get svc proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      ```
###    AWS:
      ```
      export SERVICE_IP=$(kubectl get svc proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      echo https://$SERVICE_IP:443
      ```
## 2. Get the initial administrator user name and password by running these commands:
      ```
      echo Username: $(kubectl get secrets -o jsonpath='{ .data.userName }' deepsecurity-smartcheck-auth | base64 --decode)`
      echo Password: $(kubectl get secrets -o jsonpath='{ .data.password }' deepsecurity-smartcheck-auth | base64 --decode)`
      ```
>>>>>>> 7b318846bcef49974c0ba4cabef390fa07549538
## 3. (Optional) Replace the certificate that the service is using. 
See the instructions in the README.md file under "Advanced Topics" > "Replacing the
service certificate" Use the following values in the kubectl commands:
     ```
     Release:   deepsecurity-smartcheck
     ```
     ```
     Secret:    deepsecurity-smartcheck-tls-certificate
     ```
