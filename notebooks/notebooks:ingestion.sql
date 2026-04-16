-- Create a new database
create or replace database assignment_1;

-- Switch to the database
use database assignment_1;

--  Create a Stage
CREATE OR REPLACE STAGE stage_assignment
URL='azure://tracynguyen.blob.core.windows.net/at1'
CREDENTIALS=(AZURE_SAS_TOKEN='?sv=2024-11-04&ss=b&srt=co&sp=rwdlaciytfx&se=2025-08-24T12:24:49Z&st=2025-08-24T04:09:49Z&spr=https&sig=jC5ULQvsPXtoqFT7iTo803eQt5Fz77sxplnAzB2gTbo%3D');

-- Use the command 1ist to list all the files inside your stage
list @stage_assignment;

-- Create a file format called my_csv_fmt:
CREATE OR REPLACE FILE FORMAT my_csv_fmt
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('\\N', 'NULL', 'NUL', '')
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Create an external table called ex_table_youtube_trending
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending
WITH LOCATION = @stage_assignment
FILE_FORMAT = my_csv_fmt
PATTERN = '.*_youtube_trending_data.csv';
alter external table ex_table_youtube_trending refresh;
select * from assignment_1.public.ex_table_youtube_trending limit 1;

-- Create a table named table_youtube_trending
CREATE OR REPLACE TABLE table_youtube_trending AS
SELECT
    value:c1::varchar AS video_id,
    value:c2::varchar AS title,
    value:c3::timestamp_tz AS publishedAt,
    value:c4::varchar AS channelId,
    value:c5::varchar AS channelTitle,
    value:c6::varchar AS categoryId,
    value:c7::date AS trending_date,
    value:c8::int AS view_count,
    value:c9::int AS likes,
    value:c10::int AS dislikes,
    value:c11::int AS comment_count,
    split_part(metadata$filename, '_', 1) AS country,
FROM ex_table_youtube_trending;
select*from table_youtube_trending;

-- create a file format file_format_json for youtube category
CREATE OR REPLACE FILE FORMAT file_format_json
TYPE = 'JSON'
NULL_IF = ('\\N', 'NULL', 'NUL', '');

-- Create an external table called ex_table_youtube_category
create or replace external table ex_table_youtube_category
with location = @stage_assignment
file_format = file_format_json
pattern = '.*_category_id.json';

-- refresh JSON external table
alter external table ex_table_youtube_category refresh;
select * from assignment_1.public.ex_table_youtube_category limit 1;

-- Create a table named table_youtube_category
CREATE OR REPLACE TABLE table_youtube_category AS
SELECT
    split_part(metadata$filename, '_', 1) AS country,
    f.value:id::varchar AS categoryId,
    f.value:snippet.title::varchar AS category_title
FROM ex_table_youtube_category,
     LATERAL FLATTEN(value:items) f;
select*from table_youtube_category;

-- Create a table named table_youtube_final
create or replace table table_youtube_final as
select
  UUID_STRING() as id,  
  t.video_id,
  t.title,
  t.publishedAt,
  t.channelId,
  t.channelTitle,
  t.categoryId,
  c.category_title,
  t.trending_date,
  t.view_count,
  t.likes,
  t.dislikes,
  t.comment_count,
  t.country
from table_youtube_trending  t
left join table_youtube_category c
  on  c.country   = t.country
  and c.categoryId = t.categoryId;
select * from table_youtube_final;