INSTALL httpfs;
LOAD httpfs;
SET s3_endpoint='minio:9000';
SET s3_access_key_id='admin';
SET s3_secret_access_key='password123';
SET s3_use_ssl=false;
SET s3_url_style='path';

COPY
  (
      SELECT *
      FROM read_parquet('https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet')
  )
  TO 's3://raw/green_tripdata_2025-11.parquet' (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv')) TO 's3://raw/taxi_zone_lookup.csv' (FORMAT CSV, HEADER TRUE);
