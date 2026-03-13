-- Data cleaning

SELECT * FROM ads;
SELECT * FROM videos;
SELECT * FROM ads_statistics;
SELECT * FROM platforms;
SELECT COUNT(*) AS Total_num_row   -- 1000
FROM ads; 


-- JOINING  DATA

SELECT 
v.video_id,
v.path,
v.duration,
a.ad_name,
p.website,
ad.watch_count,
ad.total_time_watched,
ad.price_per_watch
FROM videos AS v 
LEFT JOIN ads AS a  ON v.video_id = a.long_version_video_id     -- OR IN (a.long_version_video_id, a.short_version_video_id)
				OR v.video_id = a.short_version_video_id
LEFT JOIN ads_statistics AS ad ON ad.video_id = v.video_id
LEFT JOIN platforms AS p ON ad.platform_id = p.platform_id;


CREATE TABLE video_ad_performance AS
SELECT 
v.video_id,
v.path,
v.duration,
a.ad_name,
p.website,
ad.watch_count,
ad.total_time_watched,
ad.price_per_watch
FROM videos AS v 
LEFT JOIN ads AS a  ON v.video_id = a.long_version_video_id     -- OR IN (a.long_version_video_id, a.short_version_video_id)
				OR v.video_id = a.short_version_video_id
LEFT JOIN ads_statistics AS ad ON ad.video_id = v.video_id
LEFT JOIN platforms AS p ON ad.platform_id = p.platform_id;

SELECT * FROM video_ad_performance;

-- 1. Check for duplicates

SELECT 
video_id, path, duration, ad_name, website, watch_count,
total_time_watched, price_per_watch,
COUNT(*) AS duplicate_count
FROM video_ad_performance
GROUP BY video_id, path, duration, ad_name, website, watch_count,
total_time_watched, price_per_watch -- ;
HAVING COUNT(*) >1;  -- This shows which combinations are duplicated and how many times they appear.

-- 1.1 Remove duplicates
WITH duplicate_vap AS 
(
SELECT *,
ROW_NUMBER() OVER (
partition by video_id, path, duration, ad_name, website, watch_count,
total_time_watched, price_per_watch 
ORDER BY video_id) AS num_row
FROM video_ad_performance
)
SELECT*
FROM duplicate_vap  -- This shows the extra duplicate rows.
WHERE num_row >1;

-- use this to delete duplicates and keep one copy
-- -- DELETE FROM duplicate_vap
-- -- WHERE num_row > 1;

-- 2. Standardizing the Data

-- 2.1 TRIMMING of DATA
SELECT DISTINCT ad_name
FROM video_ad_performance
ORDER BY 1;


-- 3. Null values or blank values
SELECT * 
FROM video_ad_performance
WHERE ad_name is NULL;

SELECT * 
FROM video_ad_performance
WHERE ad_name is NOT NULL;

-- From the IS NOT NULL QUERY, the ad_name actually exists inside the path string.
-- So, I can now extract the filename and remove -short.mp4 or -long.mp4

-- extract the filename as ad_path
SELECT 
path,
SUBSTRING_INDEX(path,'/',-1) AS ad_path
FROM video_ad_performance;

-- remove -short.mp4 or -long.mp4
SELECT 
path,
REPLACE(REPLACE(REPLACE( SUBSTRING_INDEX(path,'/',-1), '-short.mp4',''),'-long.mp4',''),'.mp4','') extracted_ad_name
FROM video_ad_performance;

SET SQL_SAFE_UPDATES = 0;

UPDATE video_ad_performance
SET ad_name = REPLACE(
REPLACE(REPLACE( SUBSTRING_INDEX(path,'/',-1), '-short.mp4',''),'-long.mp4',''),'.mp4','')
WHERE ad_name IS NULL
AND video_id IS NOT NULL;

-- checking for NULL and N/A website
SELECT * 
FROM video_ad_performance
WHERE website is NULL
OR website = 'N/A';

-- checking for NULL and N/A in  watch_count, total_time_watched and price_per_watch
SELECT * 
FROM video_ad_performance
WHERE watch_count is NULL
AND total_time_watched is NULL;

SELECT * 
FROM video_ad_performance
WHERE (watch_count is NULL OR watch_count = 'N/A')
AND (total_time_watched is NULL OR total_time_watched = 'N/A')
AND (price_per_watch is NULL OR price_per_watch = 'N/A');

-- Check how many NULL values exist in website, missing_watch_count, total_time_watched and price_per_watch

SELECT 
COUNT(*) as Total_count,
sum(website IS NULL OR website = 'N/A') AS  missing_website,
sum(watch_count  IS NULL OR watch_count  = 'N/A') AS  missing_watch_count,
sum(total_time_watched  IS NULL OR total_time_watched  = 'N/A') AS  missing_total_time_watched,
sum(price_per_watch  IS NULL OR price_per_watch  = 'N/A') AS  missing_price_per_watch
FROM video_ad_performance;


-- UPDATE all NULL and N/A with unknown for website watch
SET SQL_SAFE_UPDATES = 0;
UPDATE video_ad_performance
SET website = 'unknown'
WHERE website is NULL
OR website = 'N/A';


SELECT * 
FROM video_ad_performance
WHERE (watch_count is NULL OR watch_count = 'N/A')
AND (total_time_watched is NULL OR total_time_watched = 'N/A')
AND (price_per_watch is NULL OR price_per_watch = 'N/A');

-- DELETE ALL THE NULL AND N/A in missing_watch_count, total_time_watched and price_per_watch
-- These missing rows has no effect on the dataset
SET SQL_SAFE_UPDATES = 0;
DELETE
FROM video_ad_performance
WHERE watch_count is NULL
AND total_time_watched is NULL 
AND price_per_watch is NULL;

-- FINAL DATASET
SELECT * 
FROM video_ad_performance

