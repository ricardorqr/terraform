output region {
  value = var.region
}

output project-name {
  value = var.project-name
}

output env {
  value = var.env
}

output oidc_provider_arn {
  value = module.eks.oidc_provider_arn
}

output hosted-zone {
  value = data.aws_route53_zone.vdmcom
}

