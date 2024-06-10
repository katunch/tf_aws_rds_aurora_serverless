variable "applicationName" {
  description = "The name of the application"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "admin_username" {
  description = "The username for the RDS admin user"
  type        = string
  default     = "admin"
}
variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "ebdb"
}

variable "serverlessv2_max_capacity" {
  description = "The maximum capacity for the Aurora Serverless v2 cluster"
  type        = number
  default     = 1.0
}

variable "serverlessv2_min_capacity" {
  description = "The minimum capacity for the Aurora Serverless v2 cluster"
  type        = number
  default     = 0.5
}

variable "cluster_backup_retention_period" {
  description = "The number of days to retain backups for the Aurora Serverless v2 cluster"
  type        = number
  default     = 7
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights for the RDS cluster. Default is false. Set at least 2ACU as minimum capacity for Performance Insights to work."
  type        = bool
  default     = false
}