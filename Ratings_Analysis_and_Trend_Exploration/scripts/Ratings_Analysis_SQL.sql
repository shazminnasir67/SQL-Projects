CREATE TABLE amazon_product_reviews (
    userId VARCHAR(255),
    productId VARCHAR(255),
    Rating DECIMAL,
    timestamp BIGINT
);

-- Data Overview & Exploration:

-- What is the total number of reviews in the dataset?
SELECT COUNT(*) FROM amazon_product_reviews;

-- How many unique products are reviewed?
SELECT  COUNT(DISTINCT ProductId) FROM amazon_product_reviews;
-- What is the distribution of review ratings (e.g., how many 1-star, 2-star, etc.)?
SELECT Rating , COUNT(*) as total_count
FROM amazon_product_reviews
GROUP BY Rating
ORDER BY Rating;
-- What are the most frequently reviewed products?
SELECT productId ,count(userId) as reviewed 
FROM amazon_product_reviews
GROUP BY productId
ORDER BY reviewed DESC
LIMIT 3;
-- How many reviews does each product category have?
SELECT productId ,count(Rating) as reviews
FROM amazon_product_reviews
GROUP BY productId
ORDER BY reviews DESC;

-- Customer Review Insights:

-- What is the average rating for each product?
SELECT productId ,AVG(Rating) as average_rating
FROM amazon_product_reviews
GROUP BY productId;
-- Which products have the highest average rating, and which have the lowest?
WITH highest_rating AS (
	SELECT productId ,ROUND(AVG(Rating),2) as high_average_rating
	FROM amazon_product_reviews
	GROUP BY productId
	ORDER BY high_average_rating desc
	LIMIT 1
),
lowest_rating AS (
	SELECT productId ,ROUND(AVG(Rating),2) as low_average_rating
	FROM amazon_product_reviews
	GROUP BY productId
	ORDER BY low_average_rating ASC
	LIMIT 1
)
SELECT high_average_rating , low_average_rating
FROM highest_rating , lowest_rating;
-- What is the distribution of reviews over time (e.g., number of reviews per month/year)?

SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month, COUNT(userId) as reviews
FROM amazon_product_reviews
GROUP BY Month
ORDER BY Month;

-- Which customers have given the most ratings?
SELECT UserId , COUNT(Rating) as ratings
FROM amazon_product_reviews
GROUP BY userId
ORDER BY ratings DESC
LIMIT 1;

-- Temporal Rating Analysis:

-- How do average ratings change over time for top-rated products?

WITH top_products AS (SELECT productId ,ROUND(AVG(Rating),2) as average_rating
	FROM amazon_product_reviews
	GROUP BY productId
	HAVING ROUND(AVG(Rating),2) >= 4.5
	LIMIT 10
)
SELECT T.productId , EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month , AVG(T.average_rating) as average_rating
FROM top_products AS T
JOIN amazon_product_reviews as P
ON T.productId = P.productId
GROUP BY T.productId , Month
ORDER BY T.productId , Month ASC;
-- Are there any seasonal trends in the ratings (e.g., higher/lower ratings during certain months or holidays)?
SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month, ROUND(AVG(Rating),2)
FROM amazon_product_reviews
GROUP BY Month
ORDER BY Month;
-- What is the distribution of ratings per day, week, or month?
SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(timestamp)) AS YEAR,
	EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month, 
	EXTRACT(DAY FROM TO_TIMESTAMP(timestamp)) AS Day,
	COUNT(rating) as frequency
FROM amazon_product_reviews
GROUP BY YEAR ,Month, DAY
ORDER BY Month;
-- Advanced SQL Query Questions:

-- Comparative Rating Analysis:
-- What are the top products with the largest variance in ratings?
SELECT productId ,VAR_pop(Rating) as variance_rating
FROM amazon_product_reviews
GROUP BY productId
ORDER BY variance_rating
LIMIT 10;
-- How do the ratings differ between products with a large number of ratings versus those with only a few ratings?
WITH product_ratings AS (
    SELECT productId,
           COUNT(Rating) AS num_ratings,
           AVG(Rating) AS avg_rating
    FROM amazon_product_reviews
    GROUP BY productId
),
rating_groups AS (
    SELECT productId,
           avg_rating,
           CASE 
               WHEN num_ratings > 100 THEN 'Many Ratings'
               ELSE 'Few Ratings'
           END AS rating_group
    FROM product_ratings
)
SELECT rating_group,
       COUNT(productId) AS num_products,
       round(AVG(avg_rating),2) AS avg_group_rating
FROM rating_groups
GROUP BY rating_group
ORDER BY rating_group;

-- Customer Behavior Insights:

-- What is the average time interval between a user's ratings for different products?
WITH user_ratings AS (
    SELECT userId,
           productId,
           TO_TIMESTAMP(timestamp) AS timestamp, 
           TO_TIMESTAMP(LEAD(timestamp) OVER (PARTITION BY userId ORDER BY timestamp)) AS next_timestamp
    FROM amazon_product_reviews
),
time_intervals AS (
    SELECT userId,
           productId,
           EXTRACT(EPOCH FROM (next_timestamp - timestamp)) AS interval_seconds
    FROM user_ratings
    WHERE next_timestamp IS NOT NULL
)
SELECT AVG(interval_seconds) / (60 * 60 * 24) AS avg_interval_days
FROM time_intervals;

-- How do a user's ratings change over time? Are there patterns indicating changes in their rating behavior?
WITH user_ratings AS (
    SELECT userId,
           EXTRACT(YEAR FROM TO_TIMESTAMP(timestamp)) AS YEAR,
	EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month, 
           AVG(Rating) AS avg_rating
    FROM amazon_product_reviews
    GROUP BY userId, year, month
)
SELECT userId,year,month,
       AVG(avg_rating) AS monthly_avg_rating
FROM user_ratings
GROUP BY userId, year, month
ORDER BY userId, year, month;

-- Are there any patterns in how users rate products over time (e.g., do users tend to give higher or lower ratings after their first rating)?
WITH user_ratings AS (
    SELECT userId,Rating,
           timestamp,
           ROW_NUMBER() OVER (PARTITION BY userId ORDER BY timestamp) AS rating_sequence
    FROM amazon_product_reviews
),
rating_comparison AS (
    SELECT userId,rating_sequence,
           Rating AS current_rating,
           FIRST_VALUE(Rating) OVER (PARTITION BY userId ORDER BY timestamp) AS first_rating
    FROM user_ratings
)
SELECT userId,
       rating_sequence,
       current_rating,
       first_rating,
       current_rating - first_rating AS rating_change
FROM rating_comparison
ORDER BY userId, rating_sequence;

-- Temporal Influence on Ratings:

-- How do ratings change after a product receives a large number of ratings in a short period?

WITH surge_periods AS (
    SELECT productId,
           week AS surge_week
    FROM (
        SELECT productId,
               DATE_TRUNC('week', TO_TIMESTAMP(timestamp )) AS week,
               COUNT(*) AS rating_count
        FROM amazon_product_reviews
        GROUP BY productId, week
        HAVING COUNT(*) >= 50  
    ) AS rating_counts
),
rating_comparison AS (
    SELECT r.productId,
           TO_TIMESTAMP(r.timestamp) AS rating_timestamp,   s.surge_week as surge_week,
           AVG(r.Rating) OVER (PARTITION BY r.productId, DATE_TRUNC('week', TO_TIMESTAMP(r.timestamp ))) AS avg_rating
    FROM amazon_product_reviews r
    JOIN surge_periods s
    ON r.productId = s.productId
    WHERE TO_TIMESTAMP(r.timestamp) < s.surge_week + INTERVAL '1 week'
       OR TO_TIMESTAMP(r.timestamp) >= s.surge_week
)
SELECT productId,
       surge_week,
       AVG(CASE WHEN rating_timestamp < surge_week THEN avg_rating ELSE NULL END) AS avg_rating_before,
       AVG(CASE WHEN rating_timestamp >= surge_week THEN avg_rating ELSE NULL END) AS avg_rating_after
FROM rating_comparison
GROUP BY productId, surge_week
ORDER BY productId, surge_week;


-- What is the correlation between the time of day or day of the week and the ratings given?
SELECT EXTRACT(DOW FROM TO_TIMESTAMP(timestamp)) AS day_of_week,
       EXTRACT(HOUR FROM TO_TIMESTAMP(timestamp)) AS hour_of_day,
       AVG(Rating) AS avg_rating
FROM amazon_product_reviews
GROUP BY day_of_week, hour_of_day
ORDER BY day_of_week, hour_of_day;

-- Impact Analysis:

-- How do the first few ratings of a product impact its overall rating trend over time?
WITH initial_ratings AS (
		SELECT productId,Rating,
        timestamp,
        ROW_NUMBER() OVER (PARTITION BY userId ORDER BY timestamp) AS rn
    FROM amazon_product_reviews
),
rating_trends AS (
	SELECT productId,
		EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS MONTH,
		AVG(Rating) as avg_rating
	FROM initial_ratings
	GROUP BY productId,Month
)
SELECT ir.productId,
       ir.rating AS initial_rating,
       rt.avg_rating AS monthly_avg_rating
FROM initial_ratings ir
JOIN rating_trends rt
ON ir.productId = rt.productId
WHERE ir.rn <= 10 
AND EXTRACT (MONTH FROM  TO_TIMESTAMP(ir.timestamp)) = rt.month
ORDER BY ir.productId, ir.timestamp;

-- Sentiment Distribution:

-- What is the distribution of ratings across the entire dataset? (This helps to understand the overall sentiment trend, where lower ratings might indicate negative sentiment and higher ratings indicate positive sentiment.)
SELECT Rating, COUNT(userID) as frequency
FROM amazon_product_reviews
GROUP BY Rating
ORDER BY Rating;
-- What percentage of the ratings are positive (e.g., 4 and 5 stars), neutral (e.g., 3 stars), and negative (e.g., 1 and 2 stars)?
SELECT 
	ROUND( COUNT(userID)*100.0/(SELECT COUNT(*) FROM amazon_product_reviews),2) as percentage,
	CASE WHEN Rating >= 4 AND Rating >= 5 THEN 'Positive'
		 WHEN Rating >= 3 AND Rating < 4 THEN 'Neutral'
		 ELSE 'Negative' END AS Ratings_segment
FROM amazon_product_reviews
GROUP BY Ratings_segment
ORDER BY percentage;

-- Temporal Trends:

-- How does the average rating for a product change over time? (e.g., monthly or yearly trends)
WITH top_products AS (SELECT productId ,ROUND(AVG(Rating),2) as average_rating
	FROM amazon_product_reviews
	GROUP BY productId
)
SELECT T.productId , EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS Month , AVG(T.average_rating) as average_rating
FROM top_products AS T
JOIN amazon_product_reviews as P
ON T.productId = P.productId
GROUP BY T.productId , Month
ORDER BY T.productId , Month ASC;

-- What are the trends for products with the most significant changes in average ratings over time?
WITH rating_changes AS(SELECT productId,
		EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS MONTH,
		AVG(Rating) as avg_rating
	FROM amazon_product_reviews
	GROUP BY productId,Month
),
rating_deltas AS (
    SELECT productId,
           MAX(avg_rating) - MIN(avg_rating) AS rating_change
    FROM rating_changes
    GROUP BY productId
    HAVING MAX(avg_rating) - MIN(avg_rating) > 2  
)
SELECT productId, rating_change
FROM rating_deltas
ORDER BY rating_change DESC
LIMIT 10;
	
-- User Behavior :

-- How do users’ average ratings change over time? Do users tend to become more positive, negative, or consistent in their ratings?
WITH user_rating_trends AS (
    SELECT userId,
           EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp)) AS rating_month,
           AVG(rating) AS avg_rating
    FROM amazon_product_reviews
    GROUP BY userId, rating_month
)
SELECT userId,
       rating_month,
       avg_rating
FROM user_rating_trends
ORDER BY userId, rating_month;
-- What is the distribution of ratings given by users who have rated multiple products? Do these users tend to rate products similarly, or is there variation in their sentiment?
WITH user_ratings AS (
    SELECT userId,COUNT(DISTINCT productId) AS num_products,
           ARRAY_AGG(rating) AS ratings
    FROM amazon_product_reviews
    GROUP BY userId
    HAVING COUNT(DISTINCT productId) > 1
)
SELECT userId,
       num_products,
       ratings,
       UNNEST(ratings) AS rating
FROM user_ratings
ORDER BY userId;

-- Are there users who consistently rate products either very high or very low? What percentage of the total ratings do these users account for?
WITH rating_extremes AS (
    SELECT userId,
           COUNT(*) AS total_ratings,
           AVG(rating) AS avg_rating
    FROM amazon_product_reviews
    GROUP BY userId
    HAVING AVG(rating) < 2 OR AVG(rating) > 4  
)
SELECT userId,
       total_ratings,
       avg_rating
FROM rating_extremes
ORDER BY avg_rating;

-- Is there a correlation between the timestamp of ratings (e.g., time of day, day of the week) and the sentiment expressed in those ratings?
SELECT EXTRACT(HOUR FROM TO_TIMESTAMP(timestamp)) AS hour_of_day,
       AVG(rating) AS avg_rating
FROM amazon_product_reviews
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Product Success Prediction:

-- Can you identify products whose initial sentiment (first 100 ratings) predicts long-term success or failure (overall average rating)?
WITH initial_ratings AS (
    SELECT productId,
           AVG(rating) AS initial_avg_rating
    FROM amazon_product_reviews
    WHERE timestamp <= (SELECT MIN(timestamp) + 2592000 FROM amazon_product_reviews)
    GROUP BY productId
),
overall_ratings AS (
    SELECT productId,
           AVG(rating) AS overall_avg_rating
    FROM amazon_product_reviews
    GROUP BY productId
)
SELECT i.productId,
       i.initial_avg_rating,
       o.overall_avg_rating
FROM initial_ratings i
JOIN overall_ratings o ON i.productId = o.productId
ORDER BY overall_avg_rating DESC;

-- What is the correlation between the volume of ratings and the average sentiment over time? Does a higher number of ratings stabilize the sentiment?
WITH rating_volumes AS (
    SELECT productId,
           EXTRACT(MONTH FROM TO_TIMESTAMP(timestamp )) AS rating_month,
           COUNT(*) AS rating_volume,
           AVG(rating) AS avg_rating
    FROM amazon_product_reviews
    GROUP BY productId, rating_month
)
SELECT CORR(rating_volume, avg_rating) AS correlation
FROM rating_volumes;
-- How does the sentiment of the first ratings compare to the sentiment after the product has received more than a certain threshold of ratings (e.g., 500 ratings)?
-- Check time boundaries

WITH time_boundaries AS (
    SELECT MIN(TO_TIMESTAMP(timestamp)) AS min_timestamp,
           MAX(TO_TIMESTAMP(timestamp )) AS max_timestamp
    FROM amazon_product_reviews
),
initial_ratings AS (
    SELECT productId,
           AVG(rating) AS initial_avg_rating
    FROM amazon_product_reviews
    CROSS JOIN time_boundaries
    WHERE TO_TIMESTAMP(timestamp) <= min_timestamp + INTERVAL '30 days'
    GROUP BY productId
),
post_threshold_ratings AS (
    SELECT productId,
           AVG(rating) AS post_threshold_avg_rating
    FROM amazon_product_reviews
    CROSS JOIN time_boundaries
    WHERE TO_TIMESTAMP(timestamp) > max_timestamp - INTERVAL '30 days'
    GROUP BY productId
)
SELECT i.productId,
       i.initial_avg_rating,
       p.post_threshold_avg_rating
FROM initial_ratings i
JOIN post_threshold_ratings p ON i.productId = p.productId
ORDER BY i.initial_avg_rating DESC;