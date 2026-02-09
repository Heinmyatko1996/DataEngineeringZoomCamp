INSTALL httpfs;
LOAD httpfs;
SET s3_endpoint='minio:9000';
SET s3_access_key_id='admin';
SET s3_secret_access_key='password123';
SET s3_use_ssl=false;
SET s3_url_style='path';

-- Use /tmp which is guaranteed to exist in Linux containers
SET temp_directory = '/tmp';
SET max_memory = '1.0 GB'; -- Set this low to trigger disk spilling early
SET preserve_insertion_order = false;

-- The rest of your COPY command...
COPY (
    SELECT
        *,
        regexp_extract(filename, 'yellow_tripdata_(\d{4})-(\d{2})', 1) AS file_year,
        regexp_extract(filename, 'yellow_tripdata_(\d{4})-(\d{2})', 2) AS file_month
    FROM read_parquet([
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet',
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet',
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-03.parquet',
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-04.parquet',
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-05.parquet',
        'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-06.parquet'
    ], filename=true)
    ORDER BY VendorID, tpep_pickup_datetime
)
TO 's3://raw/nyc_taxi/'
(FORMAT PARQUET, PARTITION_BY (file_year, file_month), OVERWRITE_OR_IGNORE);

CREATE OR REPLACE VIEW yellow_taxi_external AS
SELECT * FROM read_parquet(
    's3://raw/nyc_taxi/*/*/*.parquet',
    hive_partitioning = true
);
