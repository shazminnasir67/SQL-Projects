CREATE TABLE online_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10, 2),
    CustomerID VARCHAR(10),
    Country VARCHAR(50)
);

SELECT * FROM online_retail LIMIT 10;

-- 1. Data Extraction and Exploration

-- a. Data Overview and Quality

-- What is the total number of records in the dataset?
SELECT COUNT(*) AS total_number_ofrecords FROM online_retail;
-- What is the total number of unique transactions (InvoiceNo)?
SELECT COUNT(DISTINCT Invoiceno) AS total_number_invoices FROM online_retail;
-- What is the total number of unique products (StockCode) in the dataset?
SELECT COUNT(DISTINCT stockcode) AS total_number_stockes FROM online_retail;
-- Are there any missing values in critical columns such as InvoiceNo, StockCode, Quantity, or CustomerID?
SELECT COUNT(InvoiceNo)
FROM online_retail
WHERE InvoiceNo IS NULL
UNION ALL
SELECT  COUNT(StockCode)
FROM online_retail
WHERE StockCode IS NULL
UNION ALL
SELECT   COUNT(Quantity)
FROM online_retail
WHERE Quantity IS NULL
UNION ALL
SELECT COUNT(CustomerID) 
FROM online_retail
WHERE CustomerID IS NULL;

-- Are there any duplicate records? If so, how many and what are their characteristics?
SELECT COUNT(*) AS number_of_duplicate_groups
FROM (
    SELECT COUNT(*)
    FROM online_retail
    GROUP BY InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    HAVING COUNT(*) > 1
) AS duplicate_groups;
-- What are the primary characteristics of the most frequently occurring transactions in terms of quantity and revenue?


SELECT description , SUM(quantity) as total_sales , SUM(unitprice * quantity) as Revenue 
FROM (
	SELECT * FROM online_retail WHERE quantity >=1
)
WHERE description IS NOT NULL 
GROUP BY description 
ORDER BY total_sales DESC ,Revenue DESC
LIMIT 20;

-- How do missing values in key columns (e.g., Quantity, Revenue) affect the completeness and quality of the data?

---There are no missing values but the quality of data is surely questioned when I see the Quantity column having many negative values

-- Identify and quantify the impact of duplicate transactions on overall metrics such as total revenue and average transaction size.
SELECT 
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    COUNT(*) AS duplicate_count
FROM online_retail
GROUP BY 
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
HAVING COUNT(*) > 1;
-- Calculate the impact of duplicates
WITH 
original AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS total_revenue_with_duplicates,
        AVG(Quantity * UnitPrice) AS avg_transaction_size_with_duplicates
    FROM online_retail
    WHERE Quantity >= 0
),
no_duplicates AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS total_revenue_without_duplicates,
        AVG(Quantity * UnitPrice) AS avg_transaction_size_without_duplicates
    FROM (
        SELECT DISTINCT 
            InvoiceNo,
            StockCode,
            Description,
            Quantity,
            InvoiceDate,
            UnitPrice,
            CustomerID,
            Country
        FROM online_retail
        WHERE Quantity >= 0
    ) AS unique_transactions
)
SELECT 
    original.total_revenue_with_duplicates - no_duplicates.total_revenue_without_duplicates AS revenue_impact,
    original.avg_transaction_size_with_duplicates - no_duplicates.avg_transaction_size_without_duplicates AS avg_transaction_size_impact
FROM original, no_duplicates;

Results 24573.74	-0.1525165830036973

-- b. Data Filtering and Aggregation

-- For each transaction (InvoiceNo), what is the total number of distinct products (StockCode) purchased?
SELECT invoiceno , COUNT(DISTINCT stockcode) as Products
FROM online_retail
WHERE Quantity>=0
GROUP BY invoiceno
ORDER BY Products DESC;
-- What is the average quantity of products per transaction, excluding transactions with zero quantity?
SELECT 
    AVG(total_quantity) AS avg_quantity_per_transaction
FROM (
    SELECT 
        invoiceno,
        SUM(Quantity) AS total_quantity
    FROM 
        online_retail
    WHERE 
        Quantity > 0 
    GROUP BY 
        invoiceno
) AS transaction_totals;
-- What percentage of transactions include more than three distinct products?
WITH products_qty AS (
	SELECT invoiceno , COUNT(DISTINCT stockcode)AS Qty
	FROM  online_retail
	WHERE Quantity >0 
	GROUP BY invoiceno
)
SELECT ROUND(COUNT(invoiceno) * 100.0 /(SELECT COUNT(DISTINCT invoiceno) FROM online_retail WHERE Quantity>=0),2) AS percentage
FROM products_qty
WHERE Qty > 3;
81.11
-- How does the total revenue and quantity sold for each product vary across different regions (if available)?
-- c. Time-Based Analysis

-- How does the total quantity sold for each product vary month-to-month?
WITH aggre_data AS (
	SELECT Stockcode , EXTRACT( month FROM invoicedate) as Month , 
	SUM(Quantity) AS Total_qty_sold
	FROM online_retail
	WhERE Quantity > 0
	GROUP BY stockcode , Month
	ORDER BY month 
),
Month_over_month AS (
	SELECT Stockcode ,  Total_qty_sold ,Month ,
	LAG(total_qty_sold) OVER(Order by MONTH) as previous_month_Qty_sold
	FROM aggre_data
)SELECT Stockcode ,Total_qty_sold  ,Month ,
	abs( Total_qty_sold/previous_month_Qty_sold ) - 1 as Percentage_change
FROM month_over_month;
-- What is the average transaction value for each month?
SELECT EXTRACT( month FROM invoicedate) as Month ,AVG(Quantity*unitprice) as average_transaction 
FROM online_retail
WHERE Quantity > 0
GROUP BY Month
ORDER BY Month;

-- Are there any noticeable patterns in transaction frequency or average transaction size during specific days of the week or times of the day?
SELECT 
    InvoiceNo,
     TO_CHAR(InvoiceDate, 'Day') AS day_of_week,
    EXTRACT(HOUR FROM InvoiceDate) AS hour_of_day,
    SUM(Quantity * UnitPrice) AS transaction_size
FROM 
    online_retail
WHERE 
    Quantity > 0  
GROUP BY 
    InvoiceNo,
	day_of_week,
	hour_of_day;

SELECT 
    TO_CHAR(InvoiceDate, 'Day') AS day_of_week,  
    COUNT(DISTINCT InvoiceNo) AS transaction_count
FROM 
    online_retail
WHERE 
    Quantity > 0  
GROUP BY 
    TO_CHAR(InvoiceDate, 'Day')
ORDER BY 
    transaction_count DESC;
SELECT 
    EXTRACT(HOUR FROM InvoiceDate) AS hour_of_day,  
    COUNT(DISTINCT InvoiceNo) AS transaction_count
FROM 
    online_retail
WHERE 
    Quantity > 0  
GROUP BY 
    EXTRACT(HOUR FROM InvoiceDate)
ORDER BY 
    hour_of_day ;
SELECT 
    TO_CHAR(InvoiceDate, 'Day') AS day_of_week,  
    AVG((Quantity * UnitPrice)) AS avg_transaction_size
FROM 
    online_retail
WHERE 
    Quantity > 0  
GROUP BY 
    TO_CHAR(InvoiceDate, 'Day')
ORDER BY 
    avg_transaction_size DESC;

SELECT 
    EXTRACT(HOUR FROM InvoiceDate) AS hour_of_day,  -- Extracts the hour from the timestamp
    AVG((Quantity * UnitPrice)) AS avg_transaction_size
FROM 
    online_retail
WHERE 
    Quantity > 0  
GROUP BY 
    EXTRACT(HOUR FROM InvoiceDate)
ORDER BY 
    avg_transaction_size DESC;
	
-- d. Customer Segmentation

-- What is the average number of transactions per customer (CustomerID) over the dataset period?
WITH trans_per_cust AS (SELECT 
    DISTINCT customerid , COUNT(*) as no_of_transactions
FROM 
    online_retail
WHERE 
    Quantity > 0 
GROUP BY customerid
)
SELECT AVG(no_of_transactions) as average_transactions
FROM trans_per_cust;

-- What is the total revenue per customer, and how does it vary by country?
SELECT 
    country , customerid , SUM(Quantity*unitprice) as revenue 
FROM 
    online_retail
WHERE 
    Quantity > 0 
GROUP BY customerid,country
ORDER BY revenue DESC ;

-- What is the distribution of total spend per customer, and how does it correlate with the frequency of transactions?
SELECT 
    total_spend / transaction_count AS avg_spend_per_transaction,
    COUNT(*) AS num_customers
FROM 
    (SELECT 
        c.CustomerID,
        c.total_spend,
        t.transaction_count
     FROM 
        (SELECT 
            CustomerID,
            SUM(Quantity * UnitPrice) AS total_spend
         FROM 
            online_retail
         WHERE 
            Quantity > 0
         GROUP BY 
            CustomerID
         HAVING 
            CustomerID IS NOT NULL) AS c
     JOIN 
        (SELECT 
            CustomerID,
            COUNT(DISTINCT InvoiceNo) AS transaction_count
         FROM 
            online_retail
         WHERE 
            Quantity > 0
         GROUP BY 
            CustomerID
         HAVING 
            CustomerID IS NOT NULL) AS t
     ON 
        c.CustomerID = t.CustomerID) AS customer_spend
GROUP BY 
    avg_spend_per_transaction
ORDER BY 
    avg_spend_per_transaction DESC;

-- Identify any patterns in customer purchase behavior based on their geographic location or other available demographics.
WITH purchase_data AS (
SELECT Country , invoiceno , COUNT(*) as purchases
FROM online_retail
WHERE Quantity >0
GROUP BY Country , invoiceno
)
SELECT Country , SUM(purchases) as total_purchases
FROM purchase_data
GROUP BY Country
ORDER BY total_purchases DESC;
-- 2. Data Aggregation and Transformation
-- a. Transaction-Level Aggregation

-- For each transaction, calculate the total quantity and total revenue, and then determine the average transaction size in terms of quantity and revenue.
WITH aggregated_data AS (
	SELECT invoiceno , SUM(Quantity) as total_quantity , SUM(Quantity*unitprice) as Revenue
	FROM online_retail
	WHERE Quantity >0
	GROUP BY invoiceno
)
SELECT AVG(total_quantity) as Average_quantity_sold , AVG(Revenue) as avg_revenue
FROM aggregated_data;

-- What is the average number of distinct products purchased in transactions that exceed a specified revenue threshold?
WITH aggregated_data AS (
	SELECT invoiceno , COUNT(Stockcode) as total_products , SUM(Quantity*unitprice) as Revenue
	FROM online_retail
	WHERE Quantity >0
	GROUP BY invoiceno
	HAVING SUM(Quantity*unitprice) >5000
)
SELECT AVG(total_products) as Average_product , AVG(Revenue) as avg_revenue
FROM aggregated_data;
-- What is the proportion of the total revenue contributed by each product in each transaction?
SELECT invoiceno , Stockcode , SUM(Quantity*unitprice) as Revenue
FROM online_retail
WHERE Quantity >0
GROUP BY invoiceno , Stockcode;
-- b. Product and Revenue Analysis

-- Determine the revenue growth rate for each product over different periods (e.g., monthly or quarterly).
WITH monthly_data AS (
    SELECT 
        Stockcode, 
        EXTRACT(MONTH FROM invoicedate) as Month,
        SUM(Quantity * unitprice) as Revenue,
        LAG(SUM(Quantity * unitprice)) OVER (PARTITION BY Stockcode ORDER BY EXTRACT(MONTH FROM invoicedate)) as Previous_Revenue
    FROM online_retail
    WHERE Quantity > 0
    GROUP BY Stockcode, Month
    ORDER BY Stockcode, Month
)
SELECT 
    Stockcode,
    Month,
	CASE 
        WHEN Previous_Revenue > 0 THEN (Revenue - Previous_Revenue) / Previous_Revenue
        ELSE NULL
    END as Revenue_growth_rate
FROM monthly_data
WHERE Previous_Revenue IS NOT NULL
ORDER BY stockcode , Month;

-- Identify the top 10 products by total revenue, and how many transactions each product appears in.
SELECT Stockcode , SUM(Quantity*unitprice) as total_revenue , COUNT(invoiceno) as transactions_per_product
FROM ONLINE_RETAIL
WHERE Quantity >0 
GROUP BY stockcode
HAVING COUNT(invoiceno)> 1
ORDER BY total_revenue DESC ,transactions_per_product DESC
LIMIT 10;
-- What is the correlation between product quantity sold and revenue for each product?
SELECT corr(Quantity , (Quantity*unitprice)) as correlation
FROM ONLINE_RETAIL
WHERE Quantity >0 ;
-- c. Product Co-Occurrence

CREATE MATERIALIZED VIEW Co_occurence AS 
WITH products_per_transaction AS (
		SELECT invoiceno , Stockcode,SUM(Quantity * UnitPrice) AS Revenue
		FROM online_retail
		WHERE Quantity >0
		GROUP BY invoiceno ,Stockcode
		ORDER BY invoiceno
)
SELECT 
        a.Stockcode AS Product_A, 
        b.Stockcode AS Product_B,
        COUNT(*) AS Co_occurrence_Count
    FROM 
        products_per_transaction a
    JOIN 
        products_per_transaction b
    ON 
        a.invoiceno = b.invoiceno 
        AND a.Stockcode < b.Stockcode
    GROUP BY 
        a.Stockcode, b.Stockcode;
CREATE INDEX idx_invoiceno_stockcode
ON online_retail (invoiceno, Stockcode)
WHERE Quantity > 0;

-- For each product pair, how often do they appear together in the same transaction?

SELECT 
    Product_A, 
    Product_B, 
    Co_occurrence_Count
FROM co_occurence
ORDER BY 
    Co_occurrence_Count DESC;
	
-- What are the top 10 product combinations that frequently occur together in transactions, and how do these combinations contribute to overall revenue?
WITH products_per_transaction AS (
    SELECT 
        invoiceno, 
        Stockcode,
        SUM(Quantity * UnitPrice) AS Revenue
    FROM 
        online_retail
    WHERE 
        Quantity > 0
    GROUP BY 
        invoiceno, Stockcode
),
paired_products AS (
    SELECT 
        a.Stockcode AS Product_A, 
        b.Stockcode AS Product_B,
        COUNT(*) AS Co_occurrence_Count,
        SUM(a.Revenue + b.Revenue) AS Pair_Revenue
    FROM 
        products_per_transaction a
    JOIN 
        products_per_transaction b
    ON 
        a.invoiceno = b.invoiceno 
        AND a.Stockcode < b.Stockcode
    GROUP BY 
        a.Stockcode, b.Stockcode
),
total_revenue AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS Total_Revenue
    FROM 
        online_retail
    WHERE 
        Quantity > 0
)
SELECT 
    p.Product_A, 
    p.Product_B, 
    p.Co_occurrence_Count, 
    p.Pair_Revenue, 
    (p.Pair_Revenue / t.Total_Revenue) * 100 AS Revenue_Contribution_Percentage
FROM 
    paired_products p, total_revenue t
ORDER BY 
    p.Co_occurrence_Count DESC
LIMIT 10;

-- Identify patterns in product co-occurrence by customer segments or geographic regions.
WITH product_pairs AS (
    SELECT 
        a.Country,
        a.InvoiceNo,
        a.StockCode AS product1,
        b.StockCode AS product2
    FROM 
        online_retail a
    JOIN 
        online_retail b
    ON 
        a.InvoiceNo = b.InvoiceNo
    WHERE 
        a.StockCode < b.StockCode  
        AND a.Quantity > 0 
        AND b.Quantity > 0
)
SELECT 
    Country,
    product1,
    product2,
    co_occurrence_count
FROM 
    (SELECT 
        Country,
        product1,
        product2,
        COUNT(*) AS co_occurrence_count
     FROM 
        product_pairs
     GROUP BY 
        Country, product1, product2
     HAVING 
        COUNT(*) > 10) AS frequent_itemsets
ORDER BY 
    Country, co_occurrence_count DESC;
"Belgium"	"22326"	"POST"	38
"Belgium"	"22630"	"POST"	23
"EIRE"	"22423"	"22699"	34
"EIRE"	"22697"	"22699"	33
"France"	"23084"	"POST"	65
"France"	"21731"	"POST"	62
-- d. Customer Behavior

-- What is the lifetime value of customers based on their total spend and frequency of transactions?
SELECT 
    c.CustomerID,
    total_spend,
    transaction_count,
    total_spend / NULLIF(transaction_count, 0) AS avg_spend_per_transaction,
    total_spend AS lifetime_value
FROM 
    (SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS total_spend
     FROM 
        online_retail
     WHERE 
        Quantity > 0
     GROUP BY 
        CustomerID
     HAVING 
        CustomerID IS NOT NULL) AS c
JOIN 
    (SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS transaction_count
     FROM 
        online_retail
     WHERE 
        Quantity > 0
     GROUP BY 
        CustomerID
     HAVING 
        CustomerID IS NOT NULL) AS t
ON 
    c.CustomerID = t.CustomerID;

-- Analyze customer churn by identifying those who have not made a purchase in a certain period, and how their absence affects overall revenue.
WITH churned_customers AS (
    SELECT 
        CustomerID
    FROM 
        (SELECT 
            CustomerID,
            MAX(InvoiceDate) AS last_purchase_date
         FROM 
            online_retail
         WHERE 
            Quantity > 0
         GROUP BY 
            CustomerID) AS last_purchase
    WHERE 
        last_purchase_date < CURRENT_DATE - INTERVAL '6 months'
),
churned_revenue AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS churned_customers_revenue
    FROM 
        online_retail
    WHERE 
        CustomerID IN (SELECT CustomerID FROM churned_customers)
        AND InvoiceDate < CURRENT_DATE - INTERVAL '6 months'
),
total_revenue AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS total_revenue
    FROM 
        online_retail
    WHERE 
        InvoiceDate < CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    churned_revenue.churned_customers_revenue,
    total_revenue.total_revenue,
    (churned_revenue.churned_customers_revenue / NULLIF(total_revenue.total_revenue, 0)) * 100 AS churn_impact_percentage
FROM 
    churned_revenue, total_revenue;

-- 3. Association Rule Mining Preparation

-- a. Transaction Data Preparation

-- How does the transaction data transform into the required format for association rule mining (e.g., transaction-item matrix or basket format)?
CREATE TEMP TABLE transaction_items AS
SELECT
    InvoiceNo AS transaction_id,
    STRING_AGG(StockCode, ',') AS items
FROM
    online_retail
WHERE
    Quantity > 0
GROUP BY
    InvoiceNo;
-- Example of viewing the basket format
SELECT * FROM transaction_items;

-- What is the frequency distribution of itemsets of size 1, 2, and 3?
SELECT
    StockCode AS item,
    COUNT(DISTINCT InvoiceNo) AS item_count
FROM
    online_retail
WHERE
    Quantity > 0
GROUP BY
    StockCode
ORDER BY
    item_count DESC;


SELECT
    co_occurence.product_a as Product_A,
	co_occurence.product_b as Product_B,
    co_occurence.co_occurrence_Count AS pair_count
FROM
    Co_occurence
ORDER BY
    pair_count DESC;

WITH item_triplets AS (
    SELECT
        a.StockCode AS item1,
        b.StockCode AS item2,
        c.StockCode AS item3
    FROM
        online_retail a
    JOIN
        online_retail b ON a.InvoiceNo = b.InvoiceNo
    JOIN
        online_retail c ON b.InvoiceNo = c.InvoiceNo
    WHERE
        a.StockCode < b.StockCode
        AND b.StockCode < c.StockCode
        AND a.Quantity > 0
        AND b.Quantity > 0
        AND c.Quantity > 0
)
SELECT
    item1,
    item2,
    item3,
    COUNT(*) AS triplet_count
FROM
    item_triplets
GROUP BY
    item1, item2, item3
ORDER BY
    triplet_count DESC;

-- Identify and handle any data quality issues or inconsistencies in the transaction data before applying association rule mining.
-- Check for NULL values
SELECT
    COUNT(*) AS missing_stockcode
FROM
    online_retail
WHERE
    StockCode IS NULL;

-- Check for negative quantities
SELECT
    COUNT(*) AS negative_quantities
FROM
    online_retail
WHERE
    Quantity < 0;

CREATE TEMP TABLE clean_retail AS
SELECT
    *
FROM
    online_retail
WHERE
    Quantity > 0
    AND StockCode IS NOT NULL;
