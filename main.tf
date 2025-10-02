terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
  }
}

locals {
  enable_s3_import = length(var.s3_import_bucket_names) > 0
}

data "aws_region" "current" {}

data "aws_ec2_managed_prefix_list" "s3" {
  count = local.enable_s3_import ? 1 : 0
  name  = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "random_string" "rds_password" {
  length           = 16
  special          = false
  override_special = "_%@ "
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

  dynamic "egress" {
    for_each = local.enable_s3_import ? [1] : []
    content {
      description = "Allow RDS outbound to S3 Gateway Endpoint for data import"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3[0].id]
    }
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

  dynamic "parameter" {
    for_each = local.enable_s3_import ? { "aws_default_s3_role" = aws_iam_role.rds_s3_import[0].arn } : {}
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
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


resource "aws_db_subnet_group" "default" {
  name        = "${var.applicationName}-private"
  description = "Subnet group for ${var.applicationName} database instances."
  subnet_ids  = var.vpc_subnet_ids
}

resource "aws_iam_role" "rds_s3_import" {
  count = local.enable_s3_import ? 1 : 0
  name  = "${var.applicationName}-rds-s3-import-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "rds_s3_import" {
  count       = local.enable_s3_import ? 1 : 0
  name        = "${var.applicationName}-rds-s3-import-policy"
  description = "Allows RDS to read from specific S3 buckets for import"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = concat(
          [for bucket in var.s3_import_bucket_names : "arn:aws:s3:::${bucket}"],
          [for bucket in var.s3_import_bucket_names : "arn:aws:s3:::${bucket}/*"]
        )
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_import" {
  count      = local.enable_s3_import ? 1 : 0
  role       = aws_iam_role.rds_s3_import[0].name
  policy_arn = aws_iam_policy.rds_s3_import[0].arn
}

resource "aws_rds_cluster" "prod" {
  cluster_identifier               = "${var.applicationName}-cluster"
  engine                           = "aurora-mysql"
  engine_mode                      = "provisioned"
  engine_version                   = var.aurora_mysql_engine_version
  database_name                    = var.db_name
  master_username                  = var.admin_username
  master_password                  = random_string.rds_password.result
  storage_encrypted                = true
  vpc_security_group_ids           = [aws_security_group.rds_access.id]
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.default.name
  db_instance_parameter_group_name = aws_db_parameter_group.default.name
  db_subnet_group_name             = aws_db_subnet_group.default.name
  backup_retention_period          = var.cluster_backup_retention_period
  deletion_protection              = true

  serverlessv2_scaling_configuration {
    max_capacity = var.serverlessv2_max_capacity
    min_capacity = var.serverlessv2_min_capacity
  }

  performance_insights_enabled = var.performance_insights_enabled
  depends_on                   = [aws_security_group.rds_access]
}

resource "aws_rds_cluster_role_association" "s3_integration" {
  count = local.enable_s3_import ? 1 : 0

  db_cluster_identifier = aws_rds_cluster.prod.id
  feature_name          = "" # see https://github.com/terraform-aws-modules/terraform-aws-rds-aurora/issues/273#issuecomment-1062890486
  role_arn              = aws_iam_role.rds_s3_import[0].arn

  depends_on = [
    aws_rds_cluster.prod,
    aws_iam_role_policy_attachment.rds_s3_import
  ]
}

resource "aws_rds_cluster_instance" "instances" {
  cluster_identifier           = aws_rds_cluster.prod.id
  identifier                   = "${aws_rds_cluster.prod.id}-instance"
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.prod.engine
  engine_version               = aws_rds_cluster.prod.engine_version
  db_parameter_group_name      = aws_db_parameter_group.default.name
  performance_insights_enabled = var.performance_insights_enabled
  db_subnet_group_name         = aws_db_subnet_group.default.name

  depends_on = [aws_rds_cluster.prod]
}
