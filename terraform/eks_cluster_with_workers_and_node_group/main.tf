resource "aws_vpc" "cluster_vpc"{
  cidr_block = cidrsubnet("172.20.0.0/16",0,0)
  tags={
    Name="cluster_vpc"
  }
}

resource "aws_internet_gateway" "cluster_internet_gateway" {
  vpc_id = aws_vpc.cluster_vpc.id
  tags = { 
    Name = "cluster_igw"
  }
}

resource "aws_route_table" "cluster_rt" {
  vpc_id = aws_vpc.cluster_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_internet_gateway.id
  }
  tags = {
    Name = "cluster_rt"
  }
}

resource "aws_main_route_table_association" "cluster_rt_main" {
  vpc_id         = aws_vpc.cluster_vpc.id
  route_table_id = aws_route_table.cluster_rt.id
}

resource "aws_subnet" "cluster_subnet"{
  for_each = {af-south-1a=cidrsubnet("172.20.0.0/16",8,10),af-south-1b=cidrsubnet("172.20.0.0/16",8,20),af-south-1c=cidrsubnet("172.20.0.0/16",8,30)}
  vpc_id = aws_vpc.cluster_vpc.id
  availability_zone = each.key
  cidr_block = each.value
  map_public_ip_on_launch= true
  tags={
    Name="cluster_subnet_${each.key}"
  }
}





resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "eks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


data "aws_iam_policy" "eks_cluster_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role_policy_attachment" "eks_cluster_attach_policy_to_role" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = data.aws_iam_policy.eks_cluster_policy.arn
}

data "aws_subnet_ids" "cluster_subnet_ids" {
  vpc_id = aws_vpc.cluster_vpc.id
  depends_on = [ aws_subnet.cluster_subnet ]
}

output "aws_subnet_ids_output" {
  value = data.aws_subnet_ids.cluster_subnet_ids.ids

}




resource "aws_eks_cluster" "cluster" {
  name     = "eks_cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnet_ids.cluster_subnet_ids.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach_policy_to_role,
    aws_subnet.cluster_subnet
  ]

}






resource "aws_iam_role" "eks_cluster_worker_role" {
  name = "eks_cluster_worker_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "eks_cluster_attach_policy_to_worker_role" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])


  role       = aws_iam_role.eks_cluster_worker_role.name
  policy_arn = each.value
}






resource "aws_eks_node_group" "eks_cluster_nodegroup_ondemand" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks_cluster_nodegroup_ondemand"
  node_role_arn   = aws_iam_role.eks_cluster_worker_role.arn
  subnet_ids      = data.aws_subnet_ids.cluster_subnet_ids.ids

  labels = {
    type_of_nodegroup = "on_demand_untainted"
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach_policy_to_worker_role
  ]
}







resource "aws_eks_node_group" "eks_cluster_nodegroup_spot" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks_cluster_nodegroup_spot"
  node_role_arn   = aws_iam_role.eks_cluster_worker_role.arn
  subnet_ids      = data.aws_subnet_ids.cluster_subnet_ids.ids
  capacity_type = "SPOT"
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
   
  labels = {
    type_of_nodegroup = "spot_untainted"
  

  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach_policy_to_worker_role
  ]
}








resource "aws_launch_template" "eks_cluster_tainted_worker_node_launch_config" {
  name = "eks_cluster_tainted_worker_node_launch_config"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      delete_on_termination = true
      volume_type = "gp2"
    }
  }
  network_interfaces {
    security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
  }
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==7561478f-5b81-4e9d-9db6-aec8f463d2ab=="


--==7561478f-5b81-4e9d-9db6-aec8f463d2ab==
Content-Type: text/x-shellscript; charset="us-ascii"


#!/bin/bash
sed -i '/^KUBELET_EXTRA_ARGS=/a KUBELET_EXTRA_ARGS+=" --register-with-taints=author=shishir:NoSchedule,creator=shishir:NoSchedule"' /etc/eks/bootstrap.sh


--==7561478f-5b81-4e9d-9db6-aec8f463d2ab==--\
  EOF
  )
}






resource "aws_eks_node_group" "eks_cluster_nodegroup_ondemand_tainted" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks_cluster_nodegroup_ondemand_tainted"
  node_role_arn   = aws_iam_role.eks_cluster_worker_role.arn
  subnet_ids      = data.aws_subnet_ids.cluster_subnet_ids.ids


  launch_template {
   name = aws_launch_template.eks_cluster_tainted_worker_node_launch_config.name
   version = aws_launch_template.eks_cluster_tainted_worker_node_launch_config.latest_version
  }

         
  labels = {  
     type_of_nodegroup = "on_demand_tainted"


  }
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }


  depends_on = [
    aws_launch_template.eks_cluster_tainted_worker_node_launch_config
  ]

}





output "access_cluster" {
  value = "To access the cluster, run 'aws eks --region af-south-1 update-kubeconfig --name ${aws_eks_cluster.cluster.name}'"

}
