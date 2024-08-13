CREATE TABLE customer_churn (
    customerID VARCHAR(50) PRIMARY KEY,  
    gender VARCHAR(10),
    SeniorCitizen BOOLEAN,
    Partner BOOLEAN,
    Dependents BOOLEAN,
    tenure INT,
    PhoneService BOOLEAN,
    MultipleLines VARCHAR(50),  
    InternetService VARCHAR(50),  
    OnlineSecurity VARCHAR(50),
    OnlineBackup VARCHAR(50),
    DeviceProtection VARCHAR(50),
    TechSupport VARCHAR(50),
    StreamingTV VARCHAR(50),
    StreamingMovies VARCHAR(50),
    Contract VARCHAR(50),  
    PaperlessBilling BOOLEAN,
    PaymentMethod VARCHAR(100),  -- Some payment methods might have longer descriptions
    MonthlyCharges NUMERIC(10, 2),  -- Standardizing the monetary values
    TotalCharges NUMERIC(10, 2),  
    Churn BOOLEAN
);


-- 1. Data Exploration and Preparation
--    - >Retrieve Basic Information: 
--      - Retrieve total records, unique values, and missing values for each column.
SELECT COUNT(*) as Total_records, COUNT(DISTINCT(customerid)) as unique_values 
FROM customer_churn;

SELECT * FROM customer_churn WHERE 
ROW(gender,seniorcitizen,partner,dependents,tenure,phoneservice,multiplelines,internetservice,onlinesecurity,onlinebackup,deviceprotection,techsupport,streamingtv,streamingmovies,contract,paperlessbilling,paymentmethod,monthlycharges,totalcharges,churn) IS NULL;


--      - Basic descriptive statistics for numerical and categorical features.
SELECT AVG(monthlycharges) as average, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthlycharges) as median, STDDEV(monthlycharges) as Standard_dev
FROM customer_churn
UNION ALL
SELECT AVG(totalcharges) as average, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY totalcharges) as median, STDDEV(totalcharges) as Standard_dev
FROM customer_churn
UNION ALL
SELECT AVG(tenure) as average, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tenure) as median, STDDEV(tenure) as Standard_dev
FROM customer_churn;

	SELECT churn, AVG(monthlycharges) as Average_monthly_charges,
	AVG(tenure) as Average_tenure , 
	AVG(totalcharges) as Average_Total_charges,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthlycharges) 
        AS monthly_charges_median,
    	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tenure) 
         AS tenure_median,
    	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY totalcharges) 
        AS total_charges_median
	FROM customer_churn
	GROUP BY churn;


--  SUMMARY STATS
WITH RECURSIVE
summary_stats AS
(
 SELECT 
  ROUND(AVG(Monthlycharges), 2) AS mean,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthlycharges) AS median,
  MIN(Monthlycharges) AS min,
  MAX(Monthlycharges) AS max,
  MAX(Monthlycharges) - MIN(Monthlycharges) AS range,
  ROUND(STDDEV(Monthlycharges), 2) AS standard_deviation,
  ROUND(VARIANCE(Monthlycharges), 2) AS variance,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Monthlycharges) AS q1,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Monthlycharges) AS q3
   FROM customer_churn
),
row_summary_stats AS
(
SELECT 
 1 AS sno, 
 'mean' AS statistic, 
 mean AS value 
  FROM summary_stats
UNION
SELECT 
 2, 
 'median', 
 median 
  FROM summary_stats
UNION
SELECT 
 3, 
 'minimum', 
 min 
  FROM summary_stats
UNION
SELECT 
 4, 
 'maximum', 
 max 
  FROM summary_stats
UNION
SELECT 
 5, 
 'range', 
 range 
  FROM summary_stats
UNION
SELECT 
 6, 
 'standard deviation', 
 standard_deviation 
  FROM summary_stats
UNION
SELECT 
 7, 
 'variance', 
 variance 
  FROM summary_stats
UNION
SELECT 
 9, 
 'Q1', 
 q1 
  FROM summary_stats
UNION
SELECT 
 10, 
 'Q3', 
 q3 
  FROM summary_stats
UNION
SELECT 
 11, 
 'IQR', 
 (q3 - q1) 
  FROM summary_stats
UNION
SELECT 
 12, 
 'skewness', 
 ROUND(3 * (mean - median)::NUMERIC / standard_deviation, 2) AS skewness 
  FROM summary_stats
)
SELECT * 
 FROM row_summary_stats
  ORDER BY sno;

--What percentage of customers have TotalCharges greater than the median value? How does this percentage differ between churned and non-churned customers?
SELECT churn ,ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as percentage
FROM customer_churn
WHERE totalcharges >= (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY totalcharges) FROM customer_churn)
GROUP BY churn;
--    - **Examine Customer Demographics**:
--      - Analyze the distribution of demographics (e.g., age, gender, income).
SELECT gender ,
	ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as percentage
FROM customer_churn
GROUP BY gender;
SELECT dependents ,
	ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as percentage
FROM customer_churn
GROUP BY dependents;
SELECT * from customer_churn;
--      - Identify correlations between demographic characteristics and churn.
WITH encoded_data AS (
    SELECT 
        CASE WHEN gender = 'Male' THEN 0 
            WHEN gender = 'Female' THEN 1 
        END AS gender_encoded,
		CASE WHEN techsupport = 'No' THEN 0 
			WHEN techsupport = 'No internet service' THEN 0 
            WHEN techsupport = 'Yes' THEN 1 
        END AS techsupport_encoded,
		CASE WHEN streamingmovies = 'No' THEN 0 
			WHEN streamingmovies = 'No internet service' THEN 0 
            WHEN streamingmovies = 'Yes' THEN 1 
        END AS streamingmovies_encoded,
        CASE 
            WHEN churn = 'No' THEN 0 
            WHEN churn = 'Yes' THEN 1 
        END AS churn_encoded
    FROM 
        customer_churn
)
SELECT 
    CORR(gender_encoded, churn_encoded) AS correlation_genderVSchurn,
	CORR(techsupport_encoded, churn_encoded) AS correlation_genderVSchurn,
	CORR(streamingmovies_encoded, churn_encoded) AS correlation_streamingmoviesVSchurn
FROM 
    encoded_data;
--    - **Check Account Status**:
--      - Analyze the distribution of account tenure and its correlation with churn.
WITH encoded_data AS (
    SELECT 
		tenure,
        CASE 
            WHEN churn = 'No' THEN 0 
            WHEN churn = 'Yes' THEN 1 
        END AS churn_encoded
    FROM 
        customer_churn
)
SELECT 
    CORR(tenure, churn_encoded) AS correlation
FROM 
    encoded_data;
	
--    - **Service Usage Overview**:
--      - Retrieve and compare usage patterns an total spend between churned and non-churned customers.
SELECT churn ,SUM(totalcharges) as total_spend 
FROM customer_churn
GROUP BY churn;

--    - **Churn Rate Analysis**:
--      - Calculate churn rates across different customer segments and multiple categorical variables.

SELECT 
    gender,
    partner,
    dependents,
    internetservice,
    contract,
    paperlessbilling,
    paymentmethod,
    COUNT(*) AS segment_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        (SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / (SELECT COUNT(*) FROM customer_churn)), 
        2
    ) AS churn_rate
FROM 
    customer_churn
GROUP BY 
    gender,
    partner,
    dependents,
    internetservice,
    contract,
    paperlessbilling,
    paymentmethod
ORDER BY 
    churn_rate DESC;
	
-- What are the proportions of customers using different PaymentMethods, and how do these proportions vary between churned and non-churned customers?
SELECT churn , PaymentMethod, COUNT(*) as Customers
FROM customer_churn
GROUP BY churn,PaymentMethod
ORDER BY churn;

-- What percentage of customers who have MultipleLines also have TechSupport, and does this vary between churned and non-churned customers?
SELECT churn , ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as Customers
FROM customer_churn
WHERE MultipleLines = 'Yes' AND TechSupport = 'Yes'
GROUP BY churn
ORDER BY churn;

-- What is the distribution of InternetService types among customers with and without StreamingTV or StreamingMovies?

SELECT Streamingtv , Internetservice ,ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as Customers
FROM customer_churn
GROUP BY Streamingtv , Internetservice
UNION ALL 
SELECT Streamingmovies , Internetservice ,ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as Customers
FROM customer_churn
GROUP BY Streamingmovies , Internetservice;


-- How does the distribution of tenure differ between churned and non-churned customers across different Contract types?
SELECT churn , Contract , SUM(tenure) as tenure 
FROM customer_churn
GROUP BY churn , Contract
ORDER BY churn DESC;

-- What is the churn rate across different levels of InternetService, and how does this relate to the distribution of MonthlyCharges?
SELECT 
    InternetService,
    COUNT(CASE WHEN churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*) AS churn_rate_percentage
FROM 
    customer_churn
GROUP BY 
    InternetService;
SELECT 
    InternetService,
    churn,
    AVG(MonthlyCharges) AS average_monthly_charges,
    MIN(MonthlyCharges) AS min_monthly_charges,
    MAX(MonthlyCharges) AS max_monthly_charges,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MonthlyCharges) AS median_monthly_charges
FROM 
    customer_churn
GROUP BY 
    InternetService, churn
ORDER BY 
    InternetService, churn;

-- Compare the distribution of PaymentMethod between churned and non-churned customers. Are there significant differences?
SELECT PaymentMethod , churn ,ROUND((COUNT(customerid) * 100.0)/(SELECT COUNT(*) FROM customer_churn),2) as Customers
FROM customer_churn
GROUP BY PaymentMethod , churn
ORDER BY Customers DESC;


--  - Calculate churn rates by customer segment.
SELECT * FROM customer_churn;
SELECT 
    Contract,
    InternetService,
    PaymentMethod,
    CASE 
        WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN tenure > 24 THEN '25+ months'
    END AS tenure_range,
    COUNT(CASE WHEN churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*) AS churn_rate_percentage
FROM 
    customer_churn
GROUP BY 
    Contract, InternetService, PaymentMethod, tenure_range
ORDER BY 
    churn_rate_percentage DESC;
SELECT 
    Dependents,
    Gender,
    SeniorCitizen,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS churn_rate_percentage,
    COUNT(*) AS total_customers
FROM 
    customer_churn
GROUP BY 
    Dependents, Gender, SeniorCitizen
ORDER BY 
    churn_rate_percentage DESC;



--   Perform basic correlation analysis between features and churn using SQL functions.
-- Correlation between MonthlyCharges and churn
SELECT 
    CORR(CAST(churn AS INTEGER), MonthlyCharges) AS correlation_churn_monthlycharges
FROM 
    customer_churn;

-- Correlation between Tenure and churn
SELECT 
    CORR(CAST(churn AS INTEGER), tenure) AS correlation_churn_tenure
FROM 
    customer_churn;

-- Correlation between TotalCharges and churn
SELECT 
    CORR(CAST(churn AS INTEGER), TotalCharges) AS correlation_churn_totalcharges
FROM 
    customer_churn;

