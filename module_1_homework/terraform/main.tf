
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    minio = {
      source  = "aminueza/minio"
      version = ">= 1.0.0"
    }
  }
}

# This tells Terraform how to talk to the server once it's up
provider "minio" {
  minio_server   = "127.0.0.1:9000"
  minio_user     = "admin"
  minio_password = "password123"
  minio_ssl      = false
}

resource "minio_s3_bucket" "raw" {
  bucket = "raw"
}
