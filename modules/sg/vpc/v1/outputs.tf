output region {
  value = var.region
}

output project-name {
  value = var.project-name
}

output env {
  value = var.env
}

output public-tier-sg-id {
  value = module.public-sg.security_group_id
}

output private-tier-sg-id {
  value = module.private-sg.security_group_id
}

output database-tier-sg-id {
  value = module.database-sg.security_group_id
}
