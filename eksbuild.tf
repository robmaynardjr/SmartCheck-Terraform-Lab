provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
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
        NodeAutoScalingGroupMaxSize         = "2"
        NodeInstanceType                    = "t2.medium"
        NodeImageId                         = "${var.amiImage}"
        NodeVolumeSize                      = "20"
        KeyName                             = "${var.vpcKey}"
        VpcId                              = "${var.vpcID}"
        Subnets                            = "${var.subnet1},${var.subnet2}"
    }

}

# Storage Class
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
# Install Helm and Tiller
resource "null_resource" "helm-tiller" {
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

        sleep 30
        EOT
    }
}
# Install Smart Check
resource "null_resource" "smart-check" {
    depends_on = ["null_resource.helm-tiller"]
    provisioner "local-exec" {
        command = <<EOT
        sleep 30
        helm install \
            --name deepsecurity-smartcheck \
            --set auth.masterPassword=password \
            https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
        EOT
    }
    provisioner "local-exec" {
        when = "destroy"
        command = <<EOT
        sleep 10
        helm delete --purge deepsecurity-smartcheck
        sleep 10
        EOT

    }
}
