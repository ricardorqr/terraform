######
# EKS
######

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      automation = "terraform"
      project    = var.project-name
      env        = var.env
    }
  }
}

locals {
  tags = {
    automation = "terraform"
    project    = var.project-name
    env        = var.env
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name                    = var.project-name
  cluster_version                 = var.kubernetes-version
  vpc_id                          = var.vpc-id
  subnet_ids                      = var.private-subnet-ids
  enable_irsa                     = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
   iam_role_name                   = "${var.project-name}-eks-role"

  node_security_group_use_name_prefix = false
  node_security_group_tags            = {
    "karpenter.sh/discovery/${var.project-name}" = var.project-name
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    "worker-node" = {
      name                 = "${var.project-name}-ng"
      min_size             = 2
      desired_size         = 2
      max_size             = 50
      instance_types       = [var.node-type]
      subnet_ids           = var.private-subnet-ids
      tags                 = local.tags
      iam_role_name        = "${var.project-name}-node-group-role"
      launch_template_name = "${var.project-name}-launch-template"
      enable_monitoring    = true
      ebs_optimized        = true

      iam_role_additional_policies = {
        AmazonEKSVPCResourceController = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
        AmazonSSMManagedInstanceCore   = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        AmazonEBSCSIDriverPolicy       = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs         = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        automation                   = "terraform"
        project                      = var.project-name
        env                          = var.env
        lifecycle                    = "Ec2OnDemand"
        "karpenter.sh/capacity-type" = "on-demand"
      }
    }
  }

  tags = {
    "karpenter.sh/discovery/${var.project-name}" = var.project-name
  }
}
