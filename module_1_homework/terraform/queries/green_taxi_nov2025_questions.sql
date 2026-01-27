INSTALL httpfs;
LOAD httpfs;

SET s3_endpoint='minio:9000';
SET s3_access_key_id='admin';
SET s3_secret_access_key='password123';
SET s3_use_ssl=false;
SET s3_url_style='path';

CREATE OR REPLACE TABLE green_trips AS
SELECT *
FROM read_parquet('s3://raw/green_tripdata_2025-11.parquet');

CREATE OR REPLACE TABLE taxi_zones AS
SELECT *
FROM read_csv_auto('s3://raw/taxi_zone_lookup.csv');

----------------------------------------
-- Question 3: Counting short trips (<= 1 mile)
----------------------------------------
SELECT COUNT(*) as count_short_trips
FROM green_trips
WHERE CAST(lpep_pickup_datetime AS DATE) >= '2025-11-01' AND CAST(lpep_pickup_datetime AS DATE) < '2025-12-01'
AND trip_distance <= 1.0;
-- Expected answer: 8,007

----------------------------------------
-- Question 4: Longest trip for each day (trip_distance < 100)
----------------------------------------
SELECT DATE(lpep_pickup_datetime) AS pickup_day,
       MAX(trip_distance) AS longest_trip
FROM green_trips
WHERE trip_distance < 100
  AND CAST(lpep_pickup_datetime AS DATE) >= '2025-11-01'
  AND CAST(lpep_pickup_datetime AS DATE) <  '2025-12-01'
GROUP BY pickup_day
ORDER BY longest_trip DESC
LIMIT 1;
-- Expected answer: 2025-11-14

----------------------------------------
-- Question 5: Biggest pickup zone on 2025-11-18
----------------------------------------
SELECT tz.Zone AS pickup_zone,
       SUM(gt.total_amount) AS total_amount
FROM green_trips AS gt
JOIN taxi_zones AS tz
  ON gt.PULocationID = tz.LocationID
WHERE CAST(gt.lpep_pickup_datetime AS DATE) = '2025-11-18'
GROUP BY tz.Zone
ORDER BY total_amount DESC
LIMIT 1;

-- Expected answer: East Harlem North


----------------------------------------
-- Question 6: Largest tip for trips starting in East Harlem North (November 2025)
----------------------------------------
WITH east_harlem_north_zone AS (SELECT LocationID, "Zone" FROM taxi_zones WHERE TRIM("Zone") = 'East Harlem North')
SELECT ez."Zone" AS dropoff_zone, SUM(gt.tip_amount) AS total_tip
FROM green_trips gt
JOIN east_harlem_north_zone ez ON gt.DOLocationID = ez.LocationID
WHERE CAST(gt.lpep_pickup_datetime AS DATE) >= '2025-11-01' AND CAST(gt.lpep_pickup_datetime AS DATE) < '2025-12-01'
GROUP BY ez."Zone"
ORDER BY total_tip DESC
LIMIT 1;
-- total tip : 2978.33
