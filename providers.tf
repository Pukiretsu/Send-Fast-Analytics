terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "sendfast-analytics-terraform-state" # El bucket del Paso 1
    key            = "ingesta/ingesta.tfstate"            # Ruta del archivo dentro del bucket
    region         = "us-east-2"
    dynamodb_table = "terraform-lock-table" # La tabla del Paso 2
    encrypt        = true                   # Encriptación en reposo por defecto
  }
}

provider "aws" {
  region = var.aws_region
}