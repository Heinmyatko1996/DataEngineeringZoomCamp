terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 1. Docker Provider
provider "docker" {
}

# 2. AWS Provider (The "Trick" to manage MinIO)
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "admin"
  secret_key                  = "password123"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://localhost:9000"
  }
}

# --- NEW: Network Resource ---
resource "docker_network" "data_eng_network" {
  name = "data_eng_network"
}

# 3. Pull MinIO Image
resource "docker_image" "minio_image" {
  name         = "quay.io/minio/minio:latest"
  keep_locally = true
}

# 4. Create MinIO Container
resource "docker_container" "minio_server" {
  name     = "local_minio_server"
  hostname = "minio" # This allows DuckDB to use 'http://minio:9000'
  image    = docker_image.minio_image.image_id

  command = ["server", "/data", "--console-address", ":9001"]

  # Attach to Network
  networks_advanced {
    name = docker_network.data_eng_network.name
  }

  volumes {
    host_path      = "${path.cwd}/minio_data"
    container_path = "/data"
  }

  ports {
    internal = 9000
    external = 9000
  }

  ports {
    internal = 9001
    external = 9001
  }

  env = [
    "MINIO_ROOT_USER=admin",
    "MINIO_ROOT_PASSWORD=password123"
  ]

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
    interval     = "5s"
    retries      = 10
    start_period = "10s"
    timeout      = "5s"
  }
}

# 5. Create Bucket
resource "aws_s3_bucket" "raw" {
  bucket        = "raw"
  force_destroy = true
  depends_on    = [docker_container.minio_server]
}

# 6. DuckDB Image
resource "docker_image" "duckdb_image" {
  name         = "duckdb/duckdb:1.4.3"
  keep_locally = true
}

# 7. DuckDB Container
resource "docker_container" "duckdb" {
  name  = "duckdb"
  image = docker_image.duckdb_image.image_id

  stdin_open = true
  tty        = true

  working_dir = "/data"

  # Attach to Network
  networks_advanced {
    name = docker_network.data_eng_network.name
  }

  ports {
    internal = 4213
    external = 4213
  }

  volumes {
    host_path      = "${path.cwd}/duckdb_data"
    container_path = "/data"
  }

  volumes {
    host_path      = "${path.cwd}/queries"
    container_path = "/queries"
  }

  depends_on = [docker_container.minio_server]
}
