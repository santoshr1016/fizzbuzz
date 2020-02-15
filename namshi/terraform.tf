terraform {
  required_version = ">= 0.12.2"
  backend "s3" {
    encrypt        = false
    bucket         = "namshi-cluster-bkt"
    region         = var.aws_region
    dynamodb_table = "namshi-cluster-02-lock"
    key            = "states/namshi-cluster-02.tfstate"
  }
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.aws_region
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

