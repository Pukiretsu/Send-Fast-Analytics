terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Backend remoto preparado para CI/CD.
  # Los valores se inyectan desde GitHub Actions con -backend-config para no dejar
  # nombres de buckets/tablas acoplados al repositorio.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}


provider "aws" {
  alias  = "global"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}
