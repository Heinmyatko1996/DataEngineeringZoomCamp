# Data Engineering Zoomcamp: Kestra Module 2 Solution

This repository contains the infrastructure configuration, workflow logic, and quiz solutions for Module 2 (Workflow Orchestration) of the Data Engineering Zoomcamp.

## 🛠️ Infrastructure Setup

The environment is managed via **Terraform** and **Docker**, defining a networked stack for seamless data movement.



### Components:
* **Kestra**: Workflow Orchestrator running at `http://localhost:8080`.
* **PostgreSQL (kestra_postgres)**: Internal database for Kestra state.
* **PostgreSQL (pgdatabase)**: Data Warehouse for NY Taxi data (Database: `ny_taxi`).
* **pgAdmin**: Database management UI running at `http://localhost:8085`.

---

## 🚕 Workflow Logic & ETL Pattern

The ETL pipeline handles data extraction from GitHub, staging in Postgres, and merging into production tables. We implemented a **"Loose Staging"** pattern to handle the constraints of the NYC Taxi dataset.



### Key Features:
1. **Constraint Isolation**: Staging tables are created without `PRIMARY KEY` or `NOT NULL` constraints to allow the `COPY` command to function before IDs are generated.
2. **Deduplication**: Uses `DISTINCT ON (unique_row_id)` during the `MERGE` phase to handle identical records present in the source CSVs.
3. **Backfill Support**: Dynamically renders `trigger.date` to support bulk historical loads from 2019 through 2021.

---

## 📝 Quiz Answers & Solutions

| Q# | Question Summary | Answer |
| :--- | :--- | :--- |
| **1** | Uncompressed file size (Yellow 2020-12) | **128.3 MiB** |
| **2** | Rendered variable `file` for Green 2020-04 | **green_tripdata_2020-04.csv** |
| **3** | Total rows for Yellow Taxi in 2020 | **24,648,499** |
| **4** | Total rows for Green Taxi in 2020 | **1,734,051** |
| **5** | Total rows for Yellow Taxi in March 2021 | **1,925,152** |
| **6** | Correct Timezone property for NYC | **America/New_York** |

### 📊 Verification Queries

Run these in pgAdmin to verify the row counts:

```sql
-- Total Yellow 2020
SELECT count(*) FROM public.yellow_tripdata 
WHERE filename LIKE 'yellow_tripdata_2020%';

-- Total Green 2020
SELECT count(*) FROM public.green_tripdata 
WHERE filename LIKE 'green_tripdata_2020%';

-- Specific Month (March 2021)
SELECT count(*) FROM public.yellow_tripdata 
WHERE filename = 'yellow_tripdata_2021-03.csv';
