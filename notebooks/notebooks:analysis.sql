-- Q1) What are the 3 most viewed videos for each country in the Gamingse category for the trending_date = 2024-04-01. Order the result by country and the rank.
WITH ranked AS (
  SELECT
      country,
      title,
      channeltitle,
      view_count,
      ROW_NUMBER() OVER (
        PARTITION BY country
        ORDER BY view_count DESC
      ) AS rk
  FROM table_youtube_final
  WHERE category_title = 'Gaming'
    AND trending_date = DATE '2024-04-01'   -- correct date
)
SELECT country, title, channeltitle, view_count, rk
FROM ranked
WHERE rk <= 3
ORDER BY country, rk, view_count DESC;

-- Q2) For each country, count the number of distinct video with a title containing the word “BTS” (case insensitive) and order the result by count in a descending order.
select country, count(distinct (video_id)) as CT from table_youtube_final where upper(title) like '%BTS%' group by country order by CT desc;

-- Q3) For each country, year and month (in a single column) and only for the year 2024, which video is the most viewed and what is its likes_ratio (defined as the percentage of likes against view_count) truncated to 2 decimals. Order the result by year_month and country.
WITH ranked AS (
  SELECT
      country,
      DATE_TRUNC('month', trending_date) AS year_month,
      title,
      channeltitle,
      category_title,
      view_count,
      TRUNC( (likes / NULLIF(view_count, 0)) * 100, 2 ) AS likes_ratio,
      ROW_NUMBER() OVER (
        PARTITION BY country, DATE_TRUNC('month', trending_date)
        ORDER BY view_count DESC
      ) AS rk
  FROM table_youtube_final
  WHERE EXTRACT(YEAR FROM trending_date) = 2024
)
SELECT
    country,
    TO_CHAR(year_month, 'YYYY-MM-DD') AS year_month,
    title,
    channeltitle,
    category_title,
    view_count,
    likes_ratio
FROM ranked
WHERE rk = 1
ORDER BY year_month, country;

-- Q4) For each country, which category_title has the most distinct videos and what is its percentage (2 decimals) out of the total distinct number of videos of that country? Only look at the data from 2022. Order the result by category_title and country.
WITH vids AS (
  -- Deduplicate at the video level for 2022
  SELECT DISTINCT country, category_title, video_id
  FROM table_youtube_final
  WHERE EXTRACT(YEAR FROM trending_date) >= 2022
),
counts AS (
  -- Distinct videos per (country, category)
  SELECT
      country,
      category_title,
      COUNT(DISTINCT video_id) AS total_category_video
  FROM vids
  GROUP BY 1,2
),
totals AS (
  -- Total distinct videos per country
  SELECT
      country,
      COUNT(DISTINCT video_id) AS total_country_video
  FROM vids
  GROUP BY 1
),
ranked AS (
  SELECT
      c.country,
      c.category_title,
      c.total_category_video,
      t.total_country_video,
      TRUNC(c.total_category_video * 100.0 / NULLIF(t.total_country_video, 0), 2) AS percentage,
      ROW_NUMBER() OVER (
        PARTITION BY c.country
        ORDER BY c.total_category_video DESC, c.category_title
      ) AS rk
  FROM counts c
  JOIN totals t USING (country)
)
SELECT
    country,
    category_title,
    total_category_video,
    total_country_video,
    percentage
FROM ranked
WHERE rk = 1
ORDER BY category_title, country;

-- Q5) Which channeltitle has produced the most distinct videos and what is this number? 

SELECT channeltitle, COUNT(DISTINCT video_id) AS num_videos
FROM table_youtube_final
GROUP BY channeltitle
ORDER BY num_videos DESC limit 1;