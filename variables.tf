variable "applicationName" {
  description = "The name of the application"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The IDs of the subnets to place the db instances"
  type        = list(string)
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

variable "s3_import_role_arn" {
  description = "Optional. The ARN of the IAM role to be used for S3 import operations (e.g., LOAD DATA FROM S3). This will be set for aurora_load_from_s3_role and aws_default_s3_role."
  type        = string
  default     = null
}

variable "enable_s3_import_integration" {
  description = "If true, enables the S3 import integration by associating the s3_import_role_arn and setting the necessary cluster parameter. s3_import_role_arn must be provided if this is true."
  type        = bool
  default     = false
}

variable "aurora_mysql_engine_version" {
  description = "The version of the Aurora MySQL engine to use"
  type        = string
  default     = "8.0.mysql_aurora.3.08.2"
}

variable "additional_egress_rules" {
  description = "Additional egress rules to add to the RDS security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    prefix_list_ids = optional(list(string), [])
  }))
  default = []
}
