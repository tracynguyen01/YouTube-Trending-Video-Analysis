-- Q1) In table_youtube_category, which category_title has duplicates
--     if we don’t take into account the categoryid (return only a single row)?
select
  category_title,
  count(*) as count,
from table_youtube_category
group by category_title
having count(*) > 1
order by category_title;

-- Q2) In “table_youtube_category” which category_title only appears in one country?
select category_title, min(country) as country, count(country) as count_country from table_youtube_category group by category_title having count(distinct country) = 1;

-- Q3) In “table_youtube_final”, what is the categoryid of the missing category_titles?
-- check for the missing category_title
select
 count(*) as total_records,
 count(category_title) as records_with_category,
 count(*) - count(category_title) as records_with_null_category
from table_youtube_final;

-- select the categoryid having missing category_title, and their total rows
select categoryid, count(*) from table_youtube_final where category_title is NULL or upper(category_title) = 'UNKNOWN' group by categoryid order by categoryid;

-- Q4) Update the table_youtube_final to replace the NULL values in category_title with the answer from the previous question.
UPDATE
    table_youtube_final
SET category_title = 'Nonprofits & Activism'
WHERE category_title is NULL; 

SELECT category_title, COUNT(*) 
FROM table_youtube_final where category_title is null group by category_title; -- to verify

--Q5) In “table_youtube_final”, which video doesn’t have a channeltitle (return only the title)?
select distinct title, video_id from table_youtube_final where channeltitle is null or upper(channeltitle) = 'UNKNOWN';

-- Q6) Delete from “table_youtube_final“, any record with video_id = “#NAME?”
delete from table_youtube_final where video_id = '#NAME?';

select * from table_youtube_final where video_id = '#NAME?'; -- to verify

-- Q7) Create a new table called “table_youtube_duplicates”  containing only the “bad” duplicates by using the row_number() function.
CREATE OR REPLACE TABLE table_youtube_duplicates AS
SELECT * FROM table_youtube_final 
QUALIFY ROW_NUMBER() OVER (PARTITION BY video_id, country, trending_date ORDER BY view_count DESC) > 1;

select * from table_youtube_duplicates;

--Q8) Delete the duplicates in “table_youtube_final“ by using “table_youtube_duplicates”.
DELETE FROM
    table_youtube_final using table_youtube_duplicates
WHERE
    table_youtube_final.ID = table_youtube_duplicates.ID;

-- Q9) Count the number of rows in “table_youtube_final“ and check that it is equal to 2,597,494 rows.
select * from table_youtube_final;

select count(*) as row_number from table_youtube_final;

