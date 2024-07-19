terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

resource "random_string" "rds_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "rds_access" {
  name        = "${var.applicationName}-rds-access"
  description = "Security group for RDS access for ${var.applicationName}"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow MySQL/Aurora connections from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
  egress {
    description = "Allow all traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }
}

resource "aws_rds_cluster_parameter_group" "default" {
  name        = var.applicationName
  family      = "aurora-mysql8.0"
  description = "Cluster Parameter group for ${var.applicationName}"
  parameter {
    name         = "max_allowed_packet"
    value        = "1073741824"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_parameter_group" "default" {
  name        = var.applicationName
  family      = "aurora-mysql8.0"
  description = "Parameter group for ${var.applicationName}"
  parameter {
    name         = "max_allowed_packet"
    value        = "1073741824"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster" "prod" {
  cluster_identifier               = "${var.applicationName}-cluster"
  engine                           = "aurora-mysql"
  engine_mode                      = "provisioned"
  engine_version                   = "8.0.mysql_aurora.3.06.0"
  database_name                    = var.db_name
  master_username                  = var.admin_username
  master_password                  = random_string.rds_password.result
  storage_encrypted                = true
  vpc_security_group_ids           = [aws_security_group.rds_access.id]
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.default.name
  db_instance_parameter_group_name = aws_db_parameter_group.default.name
  backup_retention_period          = var.cluster_backup_retention_period
  deletion_protection              = true

  serverlessv2_scaling_configuration {
    max_capacity = var.serverlsessv2_max_capacity
    min_capacity = var.serverlessv2_min_capacity
  }
  depends_on = [aws_security_group.rds_access]
}

resource "aws_db_subnet_group" "default" {
  name        = "${var.applicationName}-private"
  description = "Subnet group for ${var.applicationName} database instances."
  subnet_ids  = var.vpc_subnet_ids
}

resource "aws_rds_cluster_instance" "instances" {
  cluster_identifier           = aws_rds_cluster.prod.id
  identifier                   = "${aws_rds_cluster.prod.id}-instance"
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.prod.engine
  engine_version               = aws_rds_cluster.prod.engine_version
  db_parameter_group_name      = aws_db_parameter_group.default.name
  depends_on                   = [aws_rds_cluster.prod]
  performance_insights_enabled = var.performance_insights_enabled
  db_subnet_group_name         = aws_db_subnet_group.default.name
}