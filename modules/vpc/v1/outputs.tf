output region {
  value = var.region
}

output project-name {
  value = var.project-name
}

output env {
  value = var.env
}

output vpc-id {
  value = module.vpc.vpc_id
}

output public-subnets {
  value = module.vpc.public_subnets
}

output private-subnets {
  value = module.vpc.private_subnets
}

output database-subnets {
  value = module.vpc.database_subnets
}
