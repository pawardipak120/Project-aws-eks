provider "aws" {
	profile = "default"
	region  = "ap-south-1"
}

resource "aws_iam_role" "example1" {
	name = "eks-cluster-example"
	assume_role_policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
	{
		"Effect": "Allow",
		"Principal": {
			"Service": "eks.amazonaws.com"
			},
		"Action": "sts:AssumeRole"
		}
	]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
	role       = "${aws_iam_role.example1.name}"
}
resource "aws_iam_role_policy_attachment" "example-AmazonEKSServicePolicy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
	role       = "${aws_iam_role.example1.name}"
}

resource "aws_iam_role" "example" {
	name = "eks-node-group-example"
	assume_role_policy = jsonencode({
    Statement = [{
		Action = "sts:AssumeRole"
		Effect = "Allow"
		Principal = {
			Service = "ec2.amazonaws.com"
		}
	}]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
	role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
	role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
	policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
	role       = aws_iam_role.example.name
}

resource "aws_eks_cluster" "example" {
	name     = "example"
	role_arn = "${aws_iam_role.example1.arn}"

	vpc_config {
		subnet_ids = ["subnet-2d8e3256","subnet-a58be1e9"]
	}
	

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
	depends_on = [
		"aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy"
	]
}

output "endpoint" {
	value = "${aws_eks_cluster.example.endpoint}"
}

output "kubeconfig-certificate-authority-data" {
	value = "${aws_eks_cluster.example.certificate_authority.0.data}"
}

resource "aws_eks_node_group" "example" {
	cluster_name    = aws_eks_cluster.example.name
	node_group_name = "example"
	node_role_arn   = aws_iam_role.example.arn
	subnet_ids      = ["subnet-2d8e3256","subnet-a58be1e9"]
	instance_types   = ["t3.small"]
	scaling_config {
		desired_size = 2
		max_size     = 3
		min_size     = 2
	}
	remote_access {
		ec2_ssh_key = "LinuxOs1"
	}

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
	depends_on = [
		aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
		aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
		aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
	]
}
