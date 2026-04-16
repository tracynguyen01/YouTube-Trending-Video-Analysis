-- Part 4: Business question
-- If you were to launch a new Youtube channel tomorrow, which category (excluding “Music” and “Entertainment”) of video will you be trying to create to have them appear in the top trend of Youtube? Will this strategy work in every country?
-- Dataset: table_youtube_final
-- Excluding categories: Music, Entertainment

-- SECTION 0: ALL YEARS
-- 0.1 Base filter: keep all years, exclude Music/Entertainment
CREATE OR REPLACE TEMP VIEW v_filtered_all AS
SELECT *
FROM table_youtube_final
WHERE category_title NOT IN ('Music','Entertainment');

-- 0.2 Pick a single “best” row per (country, category, video)
--     Order by likes desc, then views desc, then latest date.
CREATE OR REPLACE TEMP VIEW v_video_best_all AS
SELECT
  country,
  category_title,
  video_id,
  title,
  channeltitle,
  likes,
  view_count,
  trending_date,
  EXTRACT(YEAR FROM trending_date) AS year
FROM v_filtered_all
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY country, category_title, video_id
  ORDER BY likes DESC NULLS LAST,
           view_count DESC NULLS LAST,
           trending_date DESC
) = 1;

-- 0.3 Distinct triplets for counting
CREATE OR REPLACE TEMP VIEW v_vids_all AS
SELECT DISTINCT country, category_title, video_id
FROM v_video_best_all;

-- 0.4 Country-category counts
CREATE OR REPLACE TEMP VIEW v_country_cat_all AS
SELECT country, category_title, COUNT(DISTINCT video_id) AS distinct_videos
FROM v_vids_all
GROUP BY 1,2;

-- 0.5 Country totals
CREATE OR REPLACE TEMP VIEW v_country_tot_all AS
SELECT country, COUNT(DISTINCT video_id) AS total_videos
FROM v_vids_all
GROUP BY 1;

-- 0.6 Best category per country + share
CREATE OR REPLACE TEMP VIEW v_best_by_country_all AS
SELECT
  c.country,
  c.category_title,
  c.distinct_videos,
  t.total_videos,
  TRUNC(c.distinct_videos * 100.0 / NULLIF(t.total_videos,0), 2) AS pct_of_country,
  ROW_NUMBER() OVER (
    PARTITION BY c.country
    ORDER BY c.distinct_videos DESC, c.category_title
  ) AS rk
FROM v_country_cat_all c
JOIN v_country_tot_all t USING (country);

-- 0.7 Global category counts and global winner
CREATE OR REPLACE TEMP VIEW v_global_cat_all AS
SELECT category_title, COUNT(DISTINCT video_id) AS distinct_videos_global
FROM v_vids_all
GROUP BY 1;

CREATE OR REPLACE TEMP VIEW v_global_best_all AS
SELECT global_top_category, distinct_videos_global
FROM (
  SELECT
    category_title AS global_top_category,
    distinct_videos_global,
    ROW_NUMBER() OVER (ORDER BY distinct_videos_global DESC, category_title) AS rk
  FROM v_global_cat_all
)
WHERE rk = 1;

-- SECTION 1: YEAR 2024 ONLY
-- 1.1 Base filter: 2024 only, exclude Music/Entertainment
CREATE OR REPLACE TEMP VIEW v_filtered_2024 AS
SELECT *
FROM table_youtube_final
WHERE EXTRACT(YEAR FROM trending_date) = 2024
  AND category_title NOT IN ('Music','Entertainment');

-- 1.2 Same “best” row logic but limited to 2024
CREATE OR REPLACE TEMP VIEW v_video_best_2024 AS
SELECT
  country,
  category_title,
  video_id,
  title,
  channeltitle,
  likes,
  view_count,
  trending_date,
  EXTRACT(YEAR FROM trending_date) AS year
FROM v_filtered_2024
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY country, category_title, video_id
  ORDER BY likes DESC NULLS LAST,
           view_count DESC NULLS LAST,
           trending_date DESC
) = 1;

-- 1.3 Distinct triplets for counting (2024)
CREATE OR REPLACE TEMP VIEW v_vids_2024 AS
SELECT DISTINCT country, category_title, video_id
FROM v_video_best_2024;

-- 1.4 Country-category counts (2024)
CREATE OR REPLACE TEMP VIEW v_country_cat_2024 AS
SELECT country, category_title, COUNT(DISTINCT video_id) AS distinct_videos
FROM v_vids_2024
GROUP BY 1,2;

-- 1.5 Country totals (2024)
CREATE OR REPLACE TEMP VIEW v_country_tot_2024 AS
SELECT country, COUNT(DISTINCT video_id) AS total_videos
FROM v_vids_2024
GROUP BY 1;

-- 1.6 Best category per country + share (2024)
CREATE OR REPLACE TEMP VIEW v_best_by_country_2024 AS
SELECT
  c.country,
  c.category_title,
  c.distinct_videos,
  t.total_videos,
  TRUNC(c.distinct_videos * 100.0 / NULLIF(t.total_videos,0), 2) AS pct_of_country,
  ROW_NUMBER() OVER (
    PARTITION BY c.country
    ORDER BY c.distinct_videos DESC, c.category_title
  ) AS rk
FROM v_country_cat_2024 c
JOIN v_country_tot_2024 t USING (country);

-- 1.7 Global category counts and global winner (2024)
CREATE OR REPLACE TEMP VIEW v_global_cat_2024 AS
SELECT category_title, COUNT(DISTINCT video_id) AS distinct_videos_global
FROM v_vids_2024
GROUP BY 1;

CREATE OR REPLACE TEMP VIEW v_global_best_2024 AS
SELECT global_top_category, distinct_videos_global
FROM (
  SELECT
    category_title AS global_top_category,
    distinct_videos_global,
    ROW_NUMBER() OVER (ORDER BY distinct_videos_global DESC, category_title) AS rk
  FROM v_global_cat_2024
)
WHERE rk = 1;


/* ===========================================
   SECTION 2: FINAL OUTPUTS (ALL vs 2024)
   Run any of these independently afterwards.
   =========================================== */

-- A) Global recommendation
-- ALL YEARS
SELECT 'GLOBAL_RECOMMENDATION_ALL' AS section,
       g.global_top_category       AS recommended_category,
       g.distinct_videos_global    AS distinct_videos_worldwide
FROM v_global_best_all g;

-- 2024 ONLY
SELECT 'GLOBAL_RECOMMENDATION_2024' AS section,
       g.global_top_category        AS recommended_category,
       g.distinct_videos_global     AS distinct_videos_worldwide
FROM v_global_best_2024 g;


-- B) Best category per country (+share)
-- ALL YEARS
SELECT 'BEST_BY_COUNTRY_ALL' AS section,
       b.country,
       b.category_title  AS top_category_in_country,
       b.distinct_videos AS distinct_trending_videos,
       b.pct_of_country  AS pct_of_country
FROM v_best_by_country_all b
WHERE b.rk = 1
ORDER BY b.country;

-- 2024 ONLY
SELECT 'BEST_BY_COUNTRY_2024' AS section,
       b.country,
       b.category_title  AS top_category_in_country,
       b.distinct_videos AS distinct_trending_videos,
       b.pct_of_country  AS pct_of_country
FROM v_best_by_country_2024 b
WHERE b.rk = 1
ORDER BY b.country;


-- C) Exceptions (countries where global best ≠ country best)
-- ALL YEARS
SELECT 'EXCEPTIONS_ALL' AS section,
       b.country,
       b.category_title     AS country_top_category,
       g.global_top_category,
       b.pct_of_country
FROM v_best_by_country_all b
CROSS JOIN v_global_best_all g
WHERE b.rk = 1
  AND b.category_title <> g.global_top_category
ORDER BY b.country;

-- 2024 ONLY
SELECT 'EXCEPTIONS_2024' AS section,
       b.country,
       b.category_title     AS country_top_category,
       g.global_top_category,
       b.pct_of_country
FROM v_best_by_country_2024 b
CROSS JOIN v_global_best_2024 g
WHERE b.rk = 1
  AND b.category_title <> g.global_top_category
ORDER BY b.country;


-- D) Alignment summary (how many countries align with global best)
-- ALL YEARS
SELECT 'ALIGNMENT_SUMMARY_ALL' AS section,
       SUM(CASE WHEN b.category_title = g.global_top_category THEN 1 ELSE 0 END) AS countries_aligned,
       COUNT(*) AS total_countries,
       TRUNC(100.0 * SUM(CASE WHEN b.category_title = g.global_top_category THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS pct_countries_aligned
FROM v_best_by_country_all b
CROSS JOIN v_global_best_all g
WHERE b.rk = 1;

-- 2024 ONLY
SELECT 'ALIGNMENT_SUMMARY_2024' AS section,
       SUM(CASE WHEN b.category_title = g.global_top_category THEN 1 ELSE 0 END) AS countries_aligned,
       COUNT(*) AS total_countries,
       TRUNC(100.0 * SUM(CASE WHEN b.category_title = g.global_top_category THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS pct_countries_aligned
FROM v_best_by_country_2024 b
CROSS JOIN v_global_best_2024 g
WHERE b.rk = 1;


-- E) All videos (global), sorted by Likes then Views
-- ALL YEARS
SELECT 'ALL_VIDEOS_GLOBAL_ALL' AS section,
       country, category_title, year,
       video_id, title, channeltitle, likes, view_count, trending_date
FROM v_video_best_all
ORDER BY likes DESC NULLS LAST, view_count DESC NULLS LAST;

-- 2024 ONLY
SELECT 'ALL_VIDEOS_GLOBAL_2024' AS section,
       country, category_title, year,
       video_id, title, channeltitle, likes, view_count, trending_date
FROM v_video_best_2024
ORDER BY likes DESC NULLS LAST, view_count DESC NULLS LAST;


-- F) The best video grouped by each Country & Category (sorted within group)
-- ALL YEARS
SELECT
  'BEST_VIDEO_BY_COUNTRY_ALL' AS section,
  country,
  category_title,
  year,
  video_id,
  title,
  channeltitle,
  likes,
  view_count,
  trending_date
FROM v_video_best_all
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY country
  ORDER BY likes DESC NULLS LAST,
           view_count DESC NULLS LAST,
           trending_date DESC
) = 1
ORDER BY country;
-- 2024 ONLY
SELECT
  'BEST_VIDEO_BY_COUNTRY_2024' AS section,
  country,
  category_title,
  year,
  video_id,
  title,
  channeltitle,
  likes,
  view_count,
  trending_date
FROM v_video_best_2024
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY country
  ORDER BY likes DESC NULLS LAST,
           view_count DESC NULLS LAST,
           trending_date DESC
) = 1
ORDER BY country;