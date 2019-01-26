provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-east-2"
}

# Deploy EKS Control Plane
resource "aws_eks_cluster" "smartcheck" {
    
    name        = "smartcheck"
    role_arn    = "${var.create_role_arn}"

    vpc_config {
        security_group_ids = ["${var.eks-security-group}"]
        subnet_ids      = ["${var.subnet1}","${var.subnet2}"]
    }
    # Update local kubeconfig and test connectivity to control plane.
    provisioner "local-exec" {
        command = "aws eks update-kubeconfig --name smartcheck && kubectl get svc" 
    }
}
# Deploy k8s worker nodes
resource "aws_cloudformation_stack" "eks_nodes" {
    depends_on          = ["aws_eks_cluster.smartcheck"]
    template_url        = "https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-11-07/amazon-eks-nodegroup.yaml"
    name                = "k8s-nodes"
    capabilities        = ["CAPABILITY_IAM"]
    parameters = {
        ClusterName                         = "smartcheck"
        ClusterControlPlaneSecurityGroup    = "${var.eks-security-group}"
        NodeGroupName                       = "smartcheck-lab"
        NodeAutoScalingGroupMinSize         = "2"
        NodeAutoScalingGroupMaxSize         = "3"
        NodeInstanceType                    = "t2.medium"
        NodeImageId                         = "ami-0958a76db2d150238"
        NodeVolumeSize                      = "20"
        KeyName                             = "${var.vpcKey}"
        VpcId                              = "${var.vpcID}"
        Subnets                            = "${var.subnet1},${var.subnet2}"
    }

}
# Output NodeInstanceRole ARN Created in node cloudformation. Needed to add nodes to control plane.
output "node-role" {
        value = "${aws_cloudformation_stack.eks_nodes.outputs["NodeInstanceRole"]}"
    }
# Add nodes to EKS Control Plane
resource "null_resource" "eks_nodes" {
    depends_on = ["aws_eks_cluster.smartcheck", "aws_cloudformation_stack.eks_nodes"]
    provisioner "local-exec" {
        command = <<EOT
        python ./copy-yaml.py "${aws_cloudformation_stack.eks_nodes.outputs["NodeInstanceRole"]}"
        kubectl apply -f aws-auth-cm.yaml
        sleep 30
        kubectl get nodes
        EOT
    }
}
# Deploy Deep Security SmartCheck
resource "null_resource" "smart_check" {
    depends_on = ["null_resource.eks_nodes"]
    provisioner "local-exec" {
        command = <<EOT
        rm aws-auth-cm.yaml
        kubectl create serviceaccount \
            --namespace kube-system \
            tiller

        kubectl create clusterrolebinding tiller-cluster-role \
            --clusterrole=cluster-admin \
            --serviceaccount=kube-system:tiller

        helm init --service-account tiller

        sleep 15

        helm install \
            --name deepsecurity-smartcheck \
            --set auth.masterPassword=password \
            https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
        EOT
    }
}

# NOTES:

# It may take a few minutes for the LoadBalancer IP to be available.
# You can watch the status of the load balancer by running:

#     kubectl get svc --watch proxy

# 1. Get the application URL by running these commands:
#     Google Cloud or Azure:
#     export SERVICE_IP=$(kubectl get svc proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
#     AWS:
#     export SERVICE_IP=$(kubectl get svc proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#     echo https://$SERVICE_IP:443

# 2. Get the initial administrator user name and password by running these commands:

#     echo Username: $(kubectl get secrets -o jsonpath='{ .data.userName }' deepsecurity-smartcheck-auth | base64 --decode)
#     echo Password: $(kubectl get secrets -o jsonpath='{ .data.password }' deepsecurity-smartcheck-auth | base64 --decode)

# 3. (Optional) Replace the certificate that the service is using. See the
#    instructions in the README.md file under "Advanced Topics" > "Replacing the
#    service certificate" Use the following values in the kubectl commands:

#     Release:   deepsecurity-smartcheck
#     Secret:    deepsecurity-smartcheck-tls-certificate