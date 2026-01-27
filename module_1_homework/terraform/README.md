# Data Engineering Local Lab: Terraform + MinIO + DuckDB

This project demonstrates an **Infrastructure as Code (IaC)** approach to setting up a local data engineering environment. It replaces traditional Docker Compose files with a unified Terraform configuration that manages both local Docker containers and S3-compatible cloud resources in a single, declarative workflow.



## 🏗️ Architecture Overview

The environment is composed of three main layers managed by Terraform:

1.  **Storage (MinIO)**: A local object store mimicking AWS S3.
2.  **Database (DuckDB)**: An analytical database running in a container, optimized for S3 querying via the `httpfs` extension.
3.  **Networking**: A dedicated bridge network (`data_eng_network`) allowing `minio` and `duckdb` to communicate via internal hostnames.



---

## 🚀 Getting Started

### Prerequisites
- **Docker Desktop**: Version 4.58.0+ (Jan 2026 build)
- **Terraform**: Version 1.5.0+

### 1. Provision Infrastructure
Go into terraform/ directory and execute these below commands:
```bash
# Initialize and pull the specific Darwin/ARM64 providers
terraform init 
```

```bash
terraform apply
```

## 2. Execute SQL Queries

Place your .sql files in the automatically created /queries folder. To run them inside the containerized DuckDB instance against the persistent database file:

```bash
docker exec -it duckdb duckdb /data/main.db ".read /queries/load_to_minio.sql"
```
## 3. Cleanup

To stop and remove all managed infrastructure (containers, networks, and the S3 bucket):

```Bash
terraform destroy
```
Note: Your local .db files and MinIO raw data remain safe on your host machine even after destruction because they are stored in persistent host volumes.

## 🔧 DuckDB to MinIO Configuration
To allow DuckDB to interact with the local MinIO bucket, include this configuration header in your SQL files. This uses the internal Docker network hostname.

```SQL
-- 1. Load S3 Support
INSTALL httpfs;
LOAD httpfs;

-- 2. Configure Connection to local MinIO container
SET s3_endpoint='minio:9000'; 
SET s3_access_key_id='admin';
SET s3_secret_access_key='password123';
SET s3_use_ssl=false;
SET s3_url_style='path';

-- 3. Example Query: Read from the Terraform-created 'raw' bucket
SELECT * FROM read_parquet('s3://raw/input_data.parquet');
```
## ⚠️ Troubleshooting & Solutions
### Error	Cause	Fix
API version 1.41 is too old in Modern Docker Engine (2026) requirement.	Pin Provider version >= 3.6.2 in main.tf.
BucketNotEmpty S3 bucket has data inside during destroy.	Ensure force_destroy = true is set in the bucket resource.
Conflict: Name in use	Ghost containers from previous non-Terraform runs.	Run docker rm -f local_minio_server duckdb.

# 📂 Project Structure
Terraform maintains the following structure automatically:

```Plaintext
.
├── main.tf             # Infrastructure definition (Docker + AWS providers)
├── duckdb_data/        # Generated: Persistent DuckDB database files
├── minio_data/         # Generated: Persistent Object storage data
└── queries/            # Generated: Place your new SQL scripts here
```
