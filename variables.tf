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

variable "serverlsessv2_max_capacity" {
  description = "The maximum capacity for the Aurora Serverless v2 cluster"
  type        = number
  default     = 1.0
}

variable "serverlessv2_min_capacity" {
  description = "The minimum capacity for the Aurora Serverless v2 cluster"
  type        = number
  default     = 0.5
}