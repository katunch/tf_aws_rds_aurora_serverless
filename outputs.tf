output "rds_admin_password" {
  value       = random_string.rds_password.result
  description = "The password for the RDS admin user"
  sensitive   = true
}

output "rds_admin_username" {
  value       = var.admin_username
  description = "The username for the RDS admin user"
  sensitive   = false
}

output "rds_endpoint" {
  value       = aws_rds_cluster.prod.endpoint
  description = "The endpoint for the RDS cluster"
  sensitive   = false
}

output "db_name" {
  value       = var.db_name
  description = "The name of the database"
  sensitive   = false
}

output "rds_security_group_id" {
  value       = aws_security_group.rds_access.id
  description = "The ID of the security group that controls access to the RDS cluster"
  sensitive   = false
}