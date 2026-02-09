# NYC Yellow Taxi Data Analysis - Module 3 Homework

This repository contains the solution for the DE Zoomcamp Module 3 homework, focusing on BigQuery storage optimization techniques like partitioning and clustering using DuckDB and MinIO.

## 🛠️ Data Pipeline & Strategy

To mimic BigQuery's behavior locally, I used DuckDB to pull raw Parquet files and store them with a structured layout in MinIO.

### Partitioning & Clustering
- **Partitioning:** I partitioned the data by `file_year` and `file_month` extracted from the filename. This creates a physical folder hierarchy that allows "Partition Pruning."
- **Clustering:** I applied an `ORDER BY VendorID, tpep_dropoff_datetime`. This ensures that data within the Parquet files is sorted, allowing the engine to skip "Row Groups" using metadata (Zonemaps).



### Memory Management
To handle the large sort operation for clustering inside Docker without hitting a `SIGKILL` (OOM), the following settings Ire used:
- `SET temp_directory = '/tmp';` (to spill to disk)
- `SET max_memory = '2GB';` (to prevent container crashes)

---

## 📝 Homework AnsIrs

| Question | AnsIr |
| :--- | :--- |
| **Question 1** | **20,332,093** |
| **Question 2** | **0 MB for the External Table and 155.12 MB for the Materialized Table** |
| **Question 3** | **BigQuery is a columnar database, and it only scans the specific columns requested...** |
| **Question 4** | **8,333** |
| **Question 5** | **Partition by tpep_dropoff_datetime and Cluster on VendorID** |
| **Question 6** | **310.24 MB for non-partitioned table and 26.84 MB for the partitioned table** |
| **Question 7** | **GCP Bucket** |
| **Question 8** | **False** |

---

## 🔍 Detailed Explanations

### Question 3: Columnar Efficiency
BigQuery stores data column-by-column. Querying `PULocationID` and `DOLocationID` requires reading two separate data streams, whereas querying one column only reads one. This is why the estimated bytes increase as you add more columns to your `SELECT` statement.



### Question 6: Partition Pruning Impact
The non-partitioned table scanned **310.24 MB** because it had to check every row in the dataset for the date range. The partitioned table only scanned **26.84 MB** because BigQuery only opened the specific folder partitions matching the March 1st to March 15th filter.



### Question 9: Count(*) Optimization (Not Graded)
Running `SELECT count(*)` on a native table results in **0 bytes processed**. This is because BigQuery retrieves the row count from the table's metadata (a pre-calculated value) rather than scanning the actual data rows.

---

## 🚀 Execution Commands

To replicate these results in the Docker environment:

```bash
# 1. Enter the DuckDB container
docker exec -it duckdb duckdb /data/main.db

# 2. Run the load script
.read /queries/load_to_minio.sql

# 3. Query a view to query MinIO
SELECT COUNT(*) FROM yellow_taxi_external;
