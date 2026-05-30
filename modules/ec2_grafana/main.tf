locals {
  name                 = "${var.name_prefix}-grafana"
  short_name           = substr(replace("${var.name_prefix}-grafana", "_", "-"), 0, 24)
  create_athena_bucket = var.athena_results_bucket_arn == null
  athena_bucket_arn    = local.create_athena_bucket ? aws_s3_bucket.athena_results[0].arn : var.athena_results_bucket_arn
  athena_bucket_name   = replace(local.athena_bucket_arn, "arn:aws:s3:::", "")
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_s3_bucket" "athena_results" {
  count = local.create_athena_bucket ? 1 : 0

  bucket        = "${var.name_prefix}-athena-results-${var.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  count = local.create_athena_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.athena_results[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  count = local.create_athena_bucket ? 1 : 0

  bucket = aws_s3_bucket.athena_results[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "grafana" {
  name        = "${local.short_name}-sg"
  description = "Security Group para Grafana en EC2."
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Grafana HTTP 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_grafana_cidr_blocks
  }

  dynamic "ingress" {
    for_each = length(var.ssh_cidr_blocks) > 0 ? [1] : []

    content {
      description = "SSH opcional"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  egress {
    description = "Salida a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}

resource "aws_iam_role" "grafana" {
  name = "${local.short_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "grafana_athena" {
  name        = "${local.short_name}-athena-policy"
  description = "Permisos para Grafana EC2 sobre Athena, Glue y S3 Refined."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AthenaAccess"
        Effect = "Allow"
        Action = [
          "athena:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "GlueReadAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:SearchTables"
        ]
        Resource = "*"
      },
      {
        Sid    = "ListRefinedAndAthenaResults"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          var.refined_bucket_arn,
          local.athena_bucket_arn
        ]
      },
      {
        Sid    = "ReadRefinedObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.refined_bucket_arn}/*"
      },
      {
        Sid    = "AthenaResultsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${local.athena_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_athena" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_athena.arn
}

resource "aws_iam_instance_profile" "grafana" {
  name = "${local.short_name}-profile"
  role = aws_iam_role.grafana.name
}

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.grafana_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grafana.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.grafana.name
  key_name                    = var.key_name

  root_block_device {
    volume_size           = var.grafana_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = var.grafana_admin_password
    aws_region             = var.aws_region
    refined_bucket_name    = var.refined_bucket_name
    athena_bucket_name     = local.athena_bucket_name
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.name}-ec2"
  }

  depends_on = [
    aws_iam_role_policy_attachment.grafana_athena
  ]
}
