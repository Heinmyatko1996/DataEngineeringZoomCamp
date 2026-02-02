# --- 1. Provider & Version Requirements ---
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {}

# --- 2. Network (The bridge between containers) ---
resource "docker_network" "data_stack_net" {
  name = "data_engineering_network"
}

# --- 3. Persistent Volumes ---
resource "docker_volume" "ny_taxi_data" { name = "ny_taxi_postgres_data" }
resource "docker_volume" "kestra_pg_data" { name = "kestra_postgres_data" }
resource "docker_volume" "kestra_storage" { name = "kestra_data" }

# --- 4. Images (Pre-pulling images for speed) ---
resource "docker_image" "postgres_img" {
  name         = "postgres:18"
  keep_locally = true
}
resource "docker_image" "pgadmin_img" {
  name         = "dpage/pgadmin4"
  keep_locally = true
}
resource "docker_image" "kestra_img" {
  name         = "kestra/kestra:v1.1"
  keep_locally = true
}

# --- 5. Kestra Backend Database ---
resource "docker_container" "kestra_postgres" {
  name  = "kestra_postgres"
  image = docker_image.postgres_img.image_id
  networks_advanced { name = docker_network.data_stack_net.name }

  env = [
    "POSTGRES_DB=kestra",
    "POSTGRES_USER=kestra",
    "POSTGRES_PASSWORD=${var.kestra_db_password}"
  ]

  volumes {
    volume_name    = docker_volume.kestra_pg_data.name
    container_path = "/var/lib/postgresql"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -d kestra -U kestra"]
    interval = "10s"
    retries  = 5
  }
}

# --- 6. Kestra Main Server ---
resource "docker_container" "kestra" {
  name    = "kestra"
  image   = docker_image.kestra_img.image_id
  user    = "root"
  command = ["server", "standalone"]
  networks_advanced { name = docker_network.data_stack_net.name }

  ports {
    internal = 8080
    external = 8080
  }

  volumes {
    volume_name    = docker_volume.kestra_storage.name
    container_path = "/app/storage"
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  env = [
    "KESTRA_CONFIGURATION=datasources:\n  postgres:\n    url: jdbc:postgresql://kestra_postgres:5432/kestra\n    driverClassName: org.postgresql.Driver\n    username: kestra\n    password: ${var.kestra_db_password}\nkestra:\n  repository:\n    type: postgres\n  storage:\n    type: local\n    local:\n      basePath: \"/app/storage\"\n  queue:\n    type: postgres"
  ]

  depends_on = [docker_container.kestra_postgres]
}

# --- 7. NY Taxi Database (Data Warehouse) ---
resource "docker_container" "pgdatabase" {
  name  = "pgdatabase"
  image = docker_image.postgres_img.image_id
  networks_advanced { name = docker_network.data_stack_net.name }

  env = [
    "POSTGRES_USER=root",
    "POSTGRES_PASSWORD=${var.postgres_root_password}",
    "POSTGRES_DB=ny_taxi"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    volume_name    = docker_volume.ny_taxi_data.name
    container_path = "/var/lib/postgresql"
  }
}

# --- 8. PGAdmin (The UI to see your data) ---
resource "docker_container" "pgadmin" {
  name  = "pgadmin"
  image = docker_image.pgadmin_img.image_id
  networks_advanced { name = docker_network.data_stack_net.name }

  env = [
    "PGADMIN_DEFAULT_EMAIL=${var.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${var.postgres_root_password}"
  ]

  ports {
    internal = 80
    external = 8085
  }

  depends_on = [docker_container.pgdatabase]
}

# --- 9. Outputs (Quick access links) ---
output "kestra_url" {
  value = "http://localhost:8080"
}

output "pgadmin_url" {
  value = "http://localhost:8085"
}
