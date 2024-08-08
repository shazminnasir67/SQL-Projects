CREATE DATABASE mall_customers;
USE mall_customers;

CREATE TABLE customers (
	customerID INT primary KEY,
    Gender VARCHAR(10),
    Age INT,
    AnnualIncome INT ,
    SpendingScore int
);
    
LOAD DATA INFILE 'Mall_Customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM Customers;

-- Basic Information:

-- How many customers are there in the dataset?
SELECT DISTINCT COUNT(*) FROM CUSTOMERS;
-- What is the distribution of customers by gender?
SELECT gender , COUNT(*) FROM CUSTOMERS GROUP BY gender;

-- Age Analysis:

-- What is the average, median, and standard deviation of customer ages?
WITH RankedAges AS (
    SELECT 
        AGE,
        ROW_NUMBER() OVER (ORDER BY AGE) AS RowAsc,
        ROW_NUMBER() OVER (ORDER BY AGE DESC) AS RowDesc,
        COUNT(*) OVER () AS TotalCount
    FROM customers
),
MedianValues AS (
    SELECT 
        AVG(AGE) AS MEDIAN
    FROM RankedAges
    WHERE RowAsc IN ( (TotalCount + 1) / 2, (TotalCount + 2) / 2 )
),
MeanAndStd AS (
    SELECT 
        AVG(AGE) AS MEAN,
        STDDEV_POP(AGE) AS STD_DEV
    FROM customers
)
SELECT 
    MedianValues.MEDIAN,
    MeanAndStd.MEAN,
    MeanAndStd.STD_DEV
FROM MedianValues, MeanAndStd;

-- What is the age distribution of customers (e.g., age groups)?
SELECT age , COUNT(*) FROM CUSTOMERS GROUP BY AGE;
-- Which age group has the highest number of customers?
SELECT age , COUNT(*) as no_of_customers FROM CUSTOMERS GROUP BY AGE ORDER BY no_of_customers DESC LIMIT 1 ;


-- Income Analysis:

-- What is the average, median, and standard deviation of customers' annual income?
WITH rankedIncome AS (
	SELECT 
     AnnualIncome,
     ROW_NUMBER() OVER (ORDER BY AnnualIncome) as RowAsc,
     ROW_NUMBER() OVER (ORDER BY AnnualIncome) as DecsCRO,
     COUNT(*) OVER() as TotalCount
     From customers
),
MedianValues AS (
    SELECT 
        AVG(AnnualIncome) AS MEDIAN
    FROM rankedIncome
    WHERE RowAsc IN ( (TotalCount + 1) / 2, (TotalCount + 2) / 2 )
),
MeanAndStd AS (
    SELECT 
        AVG(AnnualIncome) AS MEAN,
        STDDEV_POP(AnnualIncome) AS STD_DEV
    FROM customers
)
SELECT 
    MedianValues.MEDIAN,
    MeanAndStd.MEAN,
    MeanAndStd.STD_DEV
FROM MedianValues, MeanAndStd;
     
-- What is the distribution of customers by income levels (e.g., income brackets)?
SELECT AnnualIncome , COUNT(*) as Customers FROM customers GROUP BY AnnualIncome;
-- Which income bracket has the highest number of customers?
SELECT AnnualIncome , COUNT(*) as Customers FROM customers GROUP BY AnnualIncome ORDER BY Customers DESC LIMIT 1;


-- Spending Score Analysis:

-- What is the average, median, and standard deviation of customers' spending scores?
WITH rankedspendingscores AS (
	SELECT 
     SpendingScore,
     ROW_NUMBER() OVER (ORDER BY SpendingScore) as RowAsc,
     ROW_NUMBER() OVER (ORDER BY SpendingScore) as DecsCRO,
     COUNT(*) OVER() as TotalCount
     From customers
),
MedianValues AS (
    SELECT 
        AVG(SpendingScore) AS MEDIAN
    FROM rankedspendingscores
    WHERE RowAsc IN ( (TotalCount + 1) / 2, (TotalCount + 2) / 2 )
),
MeanAndStd AS (
    SELECT 
        AVG(SpendingScore) AS MEAN,
        STDDEV_POP(SpendingScore) AS STD_DEV
    FROM customers
)
SELECT 
    MedianValues.MEDIAN,
    MeanAndStd.MEAN,
    MeanAndStd.STD_DEV
FROM MedianValues, MeanAndStd;
-- What is the distribution of spending scores across all customers?
SELECT SpendingScore , count(*) AS customers FROM customers GROUP BY SpendingScore;
-- How does the spending score vary across different age groups?
SELECT SpendingScore , AGE ,count(*) AS customers FROM customers GROUP BY SpendingScore,AGE ;


-- Gender-based Analysis:

-- What is the average age of male and female customers?
SELECT gender ,AVG(age) as average_age FROM customers GROUP BY gender;
-- What is the average annual income of male and female customers?
SELECT gender ,AVG(AnnualIncome) as average_Income FROM customers GROUP BY gender;
-- What is the average spending score of male and female customers?
SELECT gender ,AVG(SpendingScore) as average_SpendingScore FROM customers GROUP BY gender;

-- Income vs. Spending Score:

-- What is the correlation between annual income and spending score?
SELECT  
        (avg(AnnualIncome * SpendingScore) - avg(AnnualIncome) * avg(SpendingScore)) / 
        (sqrt(avg(AnnualIncome * AnnualIncome) - avg(AnnualIncome) * avg(AnnualIncome)) * sqrt(avg(SpendingScore * SpendingScore) - avg(SpendingScore) * avg(SpendingScore))) 
        AS correlation_coefficient_population
	FROM customers;
-- How does spending score vary across different income brackets?
SELECT AnnualIncome , SUM(SpendingScore) as totalSpending FROM customers GROUP BY AnnualIncome;
-- Identify the top 10 customers with the highest spending score and their corresponding income.
SELECT CustomerID, SpendingScore FRom customers  ORDER BY  SpendingScore DESC LIMIT 10;

-- Age vs. Income Analysis:

-- How does annual income vary across different age groups?
SELECT AGE , SUM(AnnualIncome) as annual_income From customers GROUP BY AGE;
-- What is the distribution of customers by age group and income bracket?
SELECT AGE , AnnualIncome , Count(*) as customers from customers Group by AGE , AnnualIncome;

-- Customer Segmentation:

-- How many customers fall into the high-income, high-spending category?
SELECT 
	
	CASE WHEN AnnualIncome >= (SELECT AVG(AnnualIncome) FROM customers) THEN 'high_income'
		  WHEN SpendingScore >= (SELECT AVG(SpendingScore) FROM customers) THEN 'high_Spending'
    ELSE NULL END AS Expenditure,
    COUNT(*) as customers
FROM customers
GROUP BY Expenditure HAVING Expenditure is not null ;

-- How many customers fall into the low-income, low-spending category?
SELECT 
	
	CASE WHEN AnnualIncome <= (SELECT AVG(AnnualIncome) FROM customers) THEN 'low_income'
		  WHEN SpendingScore <= (SELECT AVG(SpendingScore) FROM customers) THEN 'low_Spending'
    ELSE NULL END AS Expenditure,
    COUNT(*) as customers
FROM customers
GROUP BY Expenditure HAVING Expenditure is not null ;
-- How many customers fall into the high-income, low-spending category?
SELECT Count(*) as customers FROM customers WHERE SpendingScore <=(SELECT AVG(SpendingScore) FROM customers) AND AnnualIncome <= (SELECT AVG(AnnualIncome) FROM customers);

-- Outliers Identification:

-- Identify any outliers in terms of age, income, or spending score.
WITH Stats AS (
    SELECT 
        AVG(AGE) AS mean_value, 
        STDDEV(AGE) AS std_dev
    FROM customers
)
SELECT 
    CustomerID,  
    (AGE - mean_value) / std_dev AS z_score
FROM 
    customers, Stats
HAVING 
    ABS(z_score) > 3; 
-- NO OUTLIER
WITH Stats AS (
    SELECT 
        AVG(AnnualIncome) AS mean_value, 
        STDDEV(AnnualIncome) AS std_dev
    FROM customers
)
SELECT 
    CustomerID,  
    (AnnualIncome - mean_value) / std_dev AS z_score
FROM 
    customers, Stats
HAVING 
    ABS(z_score) > 3; 
-- No outlier

WITH Stats AS (
    SELECT 
        AVG(SpendingScore) AS mean_value, 
        STDDEV(SpendingScore) AS std_dev
    FROM customers
)
SELECT 
    CustomerID,  
    (SpendingScore - mean_value) / std_dev AS z_score
FROM 
    customers, Stats
HAVING 
    ABS(z_score) > 3; 
-- No outlier
