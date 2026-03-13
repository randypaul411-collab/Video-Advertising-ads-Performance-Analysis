# Video Advertising Performance Analysis 
# (SQL Data Cleaning & Analytics)

![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Data Cleaning](https://img.shields.io/badge/Data-Cleaning-green)
![Analytics](https://img.shields.io/badge/Data-Analytics-orange)

---

## Project Overview

This project demonstrates the use of **SQL for data integration, data cleaning, and performance analytics** in a video advertising environment. The goal was to transform raw operational data stored across multiple tables into a structured **analytics-ready dataset** that can be used to evaluate advertising performance across different platforms.

The dataset originally existed in multiple relational tables containing video metadata, advertisement information, platform data, and performance statistics. These tables were integrated using SQL joins and cleaned to remove duplicates, handle missing values, and extract missing advertisement information.

The final dataset allows meaningful analysis of **advertising engagement, watch behavior, and cost efficiency across different platforms.**

---

## Dataset Structure

The project dataset consists of four primary tables:

| Table | Description |
|------|-------------|
| **videos** | Contains metadata about video assets such as video ID, file path, and duration |
| **ads** | Contains advertisement campaign information linked to videos |
| **ads_statistics** | Contains advertising engagement metrics such as watch counts and total watch time |
| **platforms** | Contains information about websites where advertisements were displayed |

These tables were integrated into a unified dataset called:


---

## Project Objectives

The main objectives of this project were to:

- Integrate advertising datasets from multiple relational tables
- Clean and standardize raw data for analysis
- Extract missing advertisement information embedded in file paths
- Identify and remove duplicate records
- Handle missing values and incomplete performance data
- Produce a structured dataset suitable for analytics and reporting

---

## Data Integration

Multiple tables were combined using SQL **LEFT JOINs** to create a unified dataset containing:

- video metadata
- advertisement campaign names
- platform information
- advertising engagement metrics

Example SQL query used to integrate the data:

```sql
SELECT 
v.video_id,
v.path,
v.duration,
a.ad_name,
p.website,
ad.watch_count,
ad.total_time_watched,
ad.price_per_watch
FROM videos v
LEFT JOIN ads a
    ON v.video_id = a.long_version_video_id
    OR v.video_id = a.short_version_video_id
LEFT JOIN ads_statistics ad
    ON ad.video_id = v.video_id
LEFT JOIN platforms p
    ON ad.platform_id = p.platform_id;

```
---
## Data Cleaning Process

### 1. Extracting Advertisement Names
Some advertisement names were missing but embedded in the video file path. SQL string functions were used to extract the campaign name.

Example path:

/videos/2020-02-04/chats-conditionate-short.mp4

Extracted advertisement name:

chats-conditionate

SQL transformation:

```sql

UPDATE video_ad_performance
SET ad_name =
REPLACE(
REPLACE(
REPLACE(SUBSTRING_INDEX(path,'/',-1),'-short.mp4',''),'-long.mp4',''),'.mp4',''
)
WHERE ad_name IS NULL;

```

### 2. Duplicate Detection

To maintain data integrity, duplicate records were identified using the **ROW_NUMBER() window function**. This method assigns a unique sequence number to rows within partitions of identical records.

```sql
WITH duplicate_vap AS (
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY video_id, path, duration, ad_name, website,
watch_count, total_time_watched, price_per_watch
) AS num_row
FROM video_ad_performance
)
SELECT *
FROM duplicate_vap
WHERE num_row > 1;
```
### 3. Handling Missing Values

The dataset contained both **NULL values** and **"N/A" placeholders.**

Data cleaning steps included:

- standardizing missing values
- check both **NULL values** and **"N/A"** in **website, missing_watch_count, total_time_watched and price_per_watch.**

- check how many **NULL values** and **"N/A"** exist in **website, missing_watch_count, total_time_watched and price_per_watch.**
-UPDATE all NULL and N/A with unknown for website watch
- removing rows with no advertising performance metrics

Example cleaning query:
```sql
-- checking for NULL and N/A website
SELECT * 
FROM video_ad_performance
WHERE website is NULL
OR website = 'N/A';

-- check both NULL  and "N/A" in  missing_watch_count, total_time_watched and price_per_watch.
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


-- UPDATE all NULL and N/A with unknown for website's watch
SET SQL_SAFE_UPDATES = 0;  -- to avoid any update block
UPDATE video_ad_performance
SET website = 'unknown'
WHERE website is NULL
OR website = 'N/A';

- DELETE ALL THE NULL AND N/A in missing_watch_count, total_time_watched and price_per_watch

SET SQL_SAFE_UPDATES = 0;    -- to avoid any update block
DELETE
FROM video_ad_performance
WHERE watch_count is NULL
AND total_time_watched is NULL 
AND price_per_watch is NULL;
```

### 5. Materializing a SQL View

Initially, the integrated dataset was built as a SQL view.
To enable data cleaning operations such as updates and deletions, the view was converted into a physical table, allowing further transformations and data quality improvements.

---
## Final Dataset
The cleaned dataset contains the following fields:

| Column | Description|
|------|-------------|
|**video_id** |	Unique identifier for each video|
| **path**	| File location of the video |
| **duration** |	Length of the video |
| **ad_name**	| Advertisement campaign name |
| **website**	| Platform where the ad was displayed |
| **watch_count**	| Number of times the ad was watched |
| **total_time_watched** |	Total engagement time |
| **price_per_watch** |	Cost per watch |

This dataset can now support various advertising performance analyses such as:

- identifying top-performing advertisements

- comparing engagement across platforms

- analyzing watch-time distribution

- evaluating advertising cost efficiency

---
## Project Outcome
The final result is a clean, structured advertising performance dataset that enables reliable analysis of video advertising campaigns across different platforms. The project demonstrates how raw operational data can be transformed into meaningful insights using SQL-based data engineering and analytics techniques.
