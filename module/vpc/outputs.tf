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
  value = aws_vpc.vpc.id
}

output internet-gateway {
  value = aws_internet_gateway.internet-gateway
}

output public-subnet-a-id {
  value = aws_subnet.public-subnet-a.id
}

output private-subnet-a-id {
  value = aws_subnet.private-subnet-a.id
}