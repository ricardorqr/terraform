############
# Providers
############

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

terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.66.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.7"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks", "get-token", "--cluster-name", var.project-name, "--region", var.region, "--profile", var.profile
      ]
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks", "get-token", "--cluster-name", var.project-name, "--region", var.region, "--profile", var.profile
    ]
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks", "get-token", "--cluster-name", var.project-name, "--region", var.region, "--profile", var.profile
    ]
  }
}

######
# EKS
######

# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name                        = var.project-name
  cluster_version                     = var.kubernetes-version
  vpc_id                              = var.vpc-id
  subnet_ids                          = var.private-subnet-ids
  enable_irsa                         = true
  cluster_endpoint_private_access     = true
  cluster_endpoint_public_access      = true
  manage_aws_auth_configmap           = true
  node_security_group_use_name_prefix = false
  iam_role_name                       = "${var.project-name}-eks-role"

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.project-name
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
      most_recent              = true
      service_account_role_arn = module.ebs-csi-irsa-role.iam_role_arn
      resolve_conflicts        = "OVERWRITE"
    }
  }

  # Role used in Karpenter
  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  eks_managed_node_groups = {
    "worker-node" = {
      name                 = "${var.project-name}-ng"
      min_size             = 2
      desired_size         = 2
      max_size             = 100
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

      # EC2IMDSV2
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      # Encrypted EBS
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

  # Tag used in Karpenter
  tags = {
    "karpenter.sh/discovery" = var.project-name
  }
}

############
# Karpenter
############

# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/submodules/karpenter
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.13.1"

  cluster_name                    = module.eks.cluster_name
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
}

# Logout of docker to perform an unauthenticated pull against the public ECR
# https://karpenter.sh/v0.27.3/troubleshooting/#helm-error-when-pulling-the-chart
resource "null_resource" "docker-logout" {
  provisioner "local-exec" {
    command = "docker logout public.ecr.aws"
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.27.3"
  depends_on       = [null_resource.docker-logout, module.karpenter, module.eks]

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}

resource "kubectl_manifest" "karpenter-provisioner-template" {
  yaml_body  = <<-YAML
  apiVersion: karpenter.k8s.aws/v1alpha1
  kind: AWSNodeTemplate
  metadata:
    name: default
  spec:
    subnetSelector:
      karpenter.sh/discovery: ${var.project-name}
    securityGroupSelector:
      karpenter.sh/discovery: ${var.project-name}
    tags:
      karpenter.sh/discovery: ${var.project-name}
    blockDeviceMappings:
      - deviceName: /dev/xvda
        ebs:
          volumeSize: 150Gi
          volumeType: gp3
          encrypted: true
  YAML
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter-provisioner" {
  yaml_body  = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: default
  spec:
    consolidation:
      enabled: true
    providerRef:
      name: default
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
    limits:
      resources:
        cpu: 1000
    ttlSecondsUntilExpired: 2592000
  YAML
  depends_on = [helm_release.karpenter]
}

########################
# Node not ready policy
########################

# https://karpenter.sh/v0.27.3/troubleshooting/#node-terminates-before-ready-on-failed-encrypted-ebs-volume
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "node-not-ready-policy" {
  name        = "${var.project-name}-Node-NotReady-policy"
  description = "Used in Karpenter and Load Balancer Controller"
  path        = "/"
  policy      = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EBS1",
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:CreateGrant",
                "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "ec2.${var.region}.amazonaws.com",
                    "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
                }
            }
        },
        {
            "Sid": "EBS2",
            "Effect": "Allow",
            "Action": [
                "kms:DescribeCustomKeyStores",
                "kms:DescribeKey",
                "kms:Get*",
                "kms:List*",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "karpenter-attach-policy" {
  role       = module.karpenter.irsa_name
  policy_arn = aws_iam_policy.node-not-ready-policy.arn
}

################
# EBS CSI Drive
################

# https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks
module "ebs-csi-irsa-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name             = "${var.project-name}-ebs-csi-driver-role"
  policy_name_prefix    = "${var.project-name}-"
  attach_ebs_csi_policy = true

  role_policy_arns = {
    NodeNotReadyPolicy = aws_iam_policy.node-not-ready-policy.arn
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

###########################
# Load Balancer Controller
###########################

# https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks
module "aws-load-balancer-controller-irsa-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name                              = "${var.project-name}-aws-load-balancer-controller-role"
  policy_name_prefix                     = "${var.project-name}-"
  attach_load_balancer_controller_policy = true

  role_policy_arns = {
    NodeNotReadyPolicy = aws_iam_policy.node-not-ready-policy.arn
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [module.aws-load-balancer-controller-irsa-role, module.eks, helm_release.karpenter]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc-id
  }

  set {
    name  = "clusterName"
    value = var.project-name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws-load-balancer-controller-irsa-role.iam_role_arn
  }
}
