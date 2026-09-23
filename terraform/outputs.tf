output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "ecr_frontend_repository_url" {
  description = "Push frontend images here"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_repository_url" {
  description = "Push backend images here"
  value       = aws_ecr_repository.backend.repository_url
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port) - use this as DB_HOST in the backend task definition"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS hostname only (no port)"
  value       = aws_db_instance.main.address
}

output "alb_dns_name" {
  description = "Public URL of the app once ECS tasks are healthy - open this in a browser"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "codestar_connection_arn" {
  description = "After apply, go to AWS Console -> Developer Tools -> Settings -> Connections and click 'Update pending connection' to authorize GitHub access - the pipeline cannot pull source until this is done"
  value       = aws_codestarconnections_connection.github.arn
}

output "pipeline_name" {
  value = aws_codepipeline.app.name
}
