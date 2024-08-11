CREATE TABLE sales_transactions (
    Transaction_ID BIGINT PRIMARY KEY,
    Date TIMESTAMP,
    Customer_Name TEXT,
    Product TEXT[],
    Total_Items INT,
    Total_Cost NUMERIC,
    Payment_Method TEXT,
    City TEXT,
    Store_Type TEXT,
    Discount_Applied BOOLEAN,
    Customer_Category TEXT,
    Season TEXT,
    Promotion TEXT
);
SELECT * FROM sales_transactions LIMIT 10;
-- 1. **Sales Overview**:
--    - What is the total sales amount and number of transactions for each month?
SELECT 
    EXTRACT(Month FROM Date) AS month, 
    SUM(Total_Cost) AS Total_Sales,
    COUNT(Transaction_ID) AS Number_of_Transactions
FROM 
    sales_transactions
GROUP BY 
    EXTRACT(month FROM Date)
ORDER BY 
    month;

--    - What is the yearly trend in total sales and revenue?
SELECT 
    EXTRACT(YEAR FROM Date) AS Year, 
    SUM(Total_Cost) AS Total_Sales,
    COUNT(Transaction_ID) AS Number_of_Transactions
FROM 
    sales_transactions
GROUP BY 
    EXTRACT(YEAR FROM Date)
ORDER BY 
    Year;
--    - What are the month-over-month growth rates in sales for the past year?
WITH MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM Date) AS Year, 
        EXTRACT(MONTH FROM Date) AS Month,
        SUM(Total_Cost) AS Total_Sales
    FROM 
        your_table_name
    WHERE 
        EXTRACT(YEAR FROM Date) = EXTRACT(YEAR FROM CURRENT_DATE)  -- Adjust if needed for a specific year
    GROUP BY 
        EXTRACT(YEAR FROM Date), EXTRACT(MONTH FROM Date)
)
SELECT 
    Year,
    Month,
    Total_Sales,
    LAG(Total_Sales) OVER (ORDER BY Year, Month) AS Previous_Month_Sales,
    ((Total_Sales - LAG(Total_Sales) OVER (ORDER BY Year, Month)) / LAG(Total_Sales) OVER (ORDER BY Year, Month)) * 100 AS Growth_Rate
FROM 
    MonthlySales
ORDER BY 
    Year, Month;


-- 2. **Customer Insights**:
--    - Which cities have the highest and lowest total sales?
WITH sales_highest AS (
    SELECT city, SUM(total_cost) AS Total_sales
    FROM sales_transactions
    GROUP BY city
    ORDER BY Total_sales DESC
    LIMIT 1
),
sales_lowest AS (
    SELECT city, SUM(total_cost) AS Total_sales
    FROM sales_transactions
    GROUP BY city
    ORDER BY Total_sales ASC
    LIMIT 1
)
SELECT city, Total_sales
FROM sales_highest
UNION ALL
SELECT city, Total_sales
FROM sales_lowest;

--    - What are the average spending and transaction counts for each customer category?
SELECT 
    Customer_Category,
    AVG(Total_Cost) AS Average_Spending,
    COUNT(Transaction_ID) AS Transaction_Count
FROM 
    sales_transactions
GROUP BY 
    Customer_Category;

--    - What is the distribution of total spending across different customer categories?
SELECT 
    Customer_Category,
    SUM(Total_Cost) AS Total_Spending
FROM 
    sales_transactions
GROUP BY 
    Customer_Category;

-- 3. **Product Analysis**:
--    - What are the top 10 products by total sales and revenue?
WITH UnnestedProducts AS (
    SELECT 
        unnest(Product) AS Product_Name,
        Total_Items,
        Total_Cost
    FROM 
        sales_transactions
)
SELECT 
    Product_Name,
    SUM(Total_Items) AS Total_Sales,
    SUM(Total_Cost) AS Total_Revenue
FROM 
    UnnestedProducts
GROUP BY 
    Product_Name
ORDER BY 
    Total_Revenue DESC
LIMIT 10;

--    - How do sales numbers and revenue for each product vary by month?
WITH UnnestedProducts AS (
    SELECT 
        unnest(Product) AS Product_Name,
        EXTRACT(MONTH FROM Date) AS Month,
        Total_Items,
        Total_Cost
    FROM 
        sales_transactions
)
SELECT 
    Product_Name,
    Month,
    SUM(Total_Items) AS Total_Sales,
    SUM(Total_Cost) AS Total_Revenue
FROM 
    UnnestedProducts
GROUP BY 
    Product_Name, Month
ORDER BY 
    Product_Name, Month;

--    - How does the sales volume for each product correlate with total revenue over the last year?
WITH UnnestedProducts AS (
    SELECT 
        unnest(Product) AS Product_Name,
        EXTRACT(MONTH FROM Date) AS Month,
		EXTRACT(YEAR FROM date ) AS YEAR,
        Total_Items,
		date,
        Total_Cost
    FROM 
        sales_transactions
	 WHERE Date >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        Product_Name,
        SUM(Total_Items) AS Total_Sales_Volume,
        SUM(Total_Cost) AS Total_Revenue
    FROM 
        UnnestedProducts
    GROUP BY 
        Product_Name
)
SELECT 
    corr(Total_Sales_Volume, Total_Revenue) AS Sales_Revenue_Correlation
FROM 
    AggregatedData;
	
-- 4. **Store and Seasonal Trends**:
--    - What are the total sales and number of transactions for each store type?
SELECT store_type,SUM(total_cost) as total_sales ,COUNT(*) as no_of_transactions
FROM sales_transactions
GROUP BY store_type;

--    - How do sales figures and total items sold vary across different seasons?
SELECT season,SUM(total_cost) as total_sales ,SUM(Total_items) as total_item
FROM sales_transactions
GROUP BY season;
--    - What are the sales trends by store type during major sales events or holidays?
WITH HolidaySales AS (
    SELECT 
        Store_Type,
        SUM(Total_Items) AS Total_Sales,
        SUM(Total_Cost) AS Total_Revenue,
        Date
    FROM 
        sales_transactions
    WHERE 
        Date IN ('2023-11-25', '2023-12-25', '2024-01-01', '2024-02-14')   
    GROUP BY Store_Type, Date
)
SELECT 
    Store_Type,
    Date,
    Total_Sales,
    Total_Revenue
FROM 
    HolidaySales
ORDER BY 
    Store_Type, Date;

-- 5. **Discount and Promotion Impact**:

--    - How do average sales amounts compare for transactions with discounts versus those without?
SELECT discount_applied, AVG(total_cost) as average_sales_amount 
FROM sales_transactions
GROUP BY discount_applied;

--    - What are the sales totals and average discounts applied by promotion type?
SELECT promotion ,SUM(total_cost) as sales_amount 
FROM sales_transactions
GROUP BY promotion;

--    - What is the average impact of different discount percentages on total sales volume?
SELECT 
    Discount_Applied,
    SUM(Total_Items) AS Total_Sales_Volume,
    AVG(Total_Items) AS Average_Sales_Volume_Per_Transaction
FROM 
    sales_transactions
GROUP BY 
    Discount_Applied
ORDER BY 
    Discount_Applied;

-- 6. **Payment Methods**:
--    - What is the distribution of total sales by payment method?
SELECT payment_method,SUM(total_cost) as total_sales 
FROM sales_transactions
GROUP BY payment_method;
--    - How does average transaction value vary by payment method?
SELECT payment_method,AVG(total_cost) as transaction_value
FROM sales_transactions
GROUP BY payment_method;

--    - How do transaction counts and total sales compare for different payment methods?
SELECT payment_method , SUM(total_cost) as total_sales , Count(*) as transactions_count 
FROM sales_transactions
GROUP BY payment_method;

-- 7. **Transaction Analysis**:
--    - What are the average and median values of total cost per transaction?
SELECT AVG(total_cost) as average_cost , PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_cost) AS median
FROM sales_transactions;

--    - How do transaction values vary by city and store type?
SELECT  city , store_type,COUNT(*) as transactions 
FROM sales_transactions
GROUP BY city , store_type;

--    - What are the trends in average transaction value for different store types and regions?
SELECT  city , store_type, AVG(total_cost) as average_transactions 
FROM sales_transactions
GROUP BY city , store_type;

-- 8. **Sales Trends by Day and Week**:

--    - What are the average daily and weekly sales trends?
WITH DailySales as ( SELECT Date::date AS Day ,
      SUM(Total_Items) AS Total_Sales_Volume,
       SUM(Total_Cost) AS Total_Revenue
    FROM 
        sales_transactions
    GROUP BY 
        Day
)
SELECT AVG(Total_Sales_Volume) AS Average_Daily_Sales_Volume,
    AVG(Total_Revenue) AS Average_Daily_Revenue
FROM 
    DailySales;
WITH WeeklySales AS (
    SELECT 
        EXTRACT(WEEK FROM Date) AS Week_Number,  
        SUM(Total_Items) AS Total_Sales_Volume,
        SUM(Total_Cost) AS Total_Revenue
    FROM 
        sales_transactions
    GROUP BY 
        Week_Number
)
SELECT 
    AVG(Total_Sales_Volume) AS Average_Weekly_Sales_Volume,
    AVG(Total_Revenue) AS Average_Weekly_Revenue
FROM 
    WeeklySales;

--    - How do sales patterns differ on weekends versus weekdays?
WITH days_of_weeks AS (SELECT EXTRACT (dow FROM date) as day, SUM(total_Items) as total_sales,
 CASE WHEN EXTRACT (dow FROM date) >=1 And EXTRACT (dow FROM date) <=5 THEN 'weekday'
      WHEN EXTRACT (dow FROM date) = 0 or EXTRACT (dow FROM date) = 6 THEN 'weekend'
	  END AS week
FROM sales_transactions
GROUP BY day
)
SELECT week , SUM(total_sales) as sales
FROM days_of_weeks
GROUP BY week;

--    - What are the sales patterns during major sales promotions or events throughout the week?
WITH EventSales AS (
    SELECT 
        EXTRACT(DOW FROM Date) AS Day_Of_Week,  
        SUM(Total_Items) AS total_sales_Volume,
        SUM(Total_Cost) AS total_revenue
    FROM 
        sales_transactions
    WHERE 
       Date >= '2023-11-25 00:00:00' AND Date < '2023-11-26 00:00:00'  
        OR Date >= '2023-12-25 00:00:00' AND Date < '2023-12-26 00:00:00'
        OR Date >= '2024-01-01 00:00:00' AND Date < '2024-01-02 00:00:00'
        OR Date >= '2024-02-14 00:00:00' AND Date < '2024-02-15 00:00:00'
   GROUP BY 
        Day_Of_Week
)
SELECT 
    CASE 
        WHEN Day_Of_Week = 0 THEN 'Sunday'
        WHEN Day_Of_Week = 1 THEN 'Monday'
        WHEN Day_Of_Week = 2 THEN 'Tuesday'
        WHEN Day_Of_Week = 3 THEN 'Wednesday'
        WHEN Day_Of_Week = 4 THEN 'Thursday'
        WHEN Day_Of_Week = 5 THEN 'Friday'
        WHEN Day_Of_Week = 6 THEN 'Saturday'
    END AS Day_Name,
    total_sales_Volume,
    total_revenue
FROM 
    EventSales
ORDER BY 
    Day_Of_Week;

-- 9. **Product Performance Over Time**:
--    - What are the sales trends for the top and bottom-performing products over the last year?
WITH unnestedProduct AS (
	 SELECT 
        unnest(Product) AS Product_Name,
        SUM(total_cost) as total_cost,
		COUNT(*) AS total_sales
    FROM 
        sales_transactions
	WHERE DATE >=current_date - INTERVAL '1 year'
	GROUP BY Product_Name
),
RankedProducts AS (
    SELECT 
        Product_Name,
        Total_Cost,
        Total_Sales,
        ROW_NUMBER() OVER (ORDER BY Total_Cost DESC) AS Rank_Desc,
        ROW_NUMBER() OVER (ORDER BY Total_Cost ASC) AS Rank_Asc
    FROM 
        UnnestedProduct
)
SELECT 
    Product_Name,
    Total_Cost,
    Total_Sales,
    CASE 
        WHEN Rank_Desc = 1 THEN 'Top Performing'
        WHEN Rank_Asc = 1 THEN 'Lowest Performing'
        ELSE 'Other'
    END AS Performance
FROM 
    RankedProducts
WHERE 
    Rank_Desc = 1
    OR Rank_Asc = 1;
	

-- 10. **Customer Purchase Patterns**:
--     - What are the most frequent purchase intervals for repeat customers?

WITH repeat_customers as (SELECT COUNT(transaction_id)  , customer_name 
FROM sales_transactions
GROUP BY customer_name
HAVING COUNT(transaction_id)>1
),
CustomerTransactions AS (
    SELECT 
        st.Customer_Name, 
        st.Date,
        LAG(st.Date) OVER (PARTITION BY st.Customer_Name ORDER BY st.Date) AS Previous_Date
    FROM 
        sales_transactions st
    WHERE 
        st.Customer_Name IN (SELECT Customer_Name FROM repeat_Customers)
),
PurchaseIntervals AS (
    SELECT
        Customer_Name,
        Date,
        Previous_Date,
        DATE_PART('day', Date - Previous_Date) AS Interval_Days
    FROM 
        CustomerTransactions
    WHERE 
        Previous_Date IS NOT NULL
)
SELECT
    Interval_Days,
    COUNT(*) AS Frequency
FROM 
    PurchaseIntervals
GROUP BY 
    Interval_Days
ORDER BY 
    Frequency DESC
LIMIT 5;  
--     - How does customer spending behavior change based on discounts and promotions?
SELECT  SUM(total_cost) as total_spendings ,AVG(total_cost) as average_transaction,customer_category ,
	CASE WHEN discount_Applied = 'true' AND promotion <> 'None' THEN 'HIGH'
		 WHEN discount_Applied = 'true' AND promotion = 'None' THEN 'MED'
		 WHEN discount_Applied = 'false' AND promotion  <> 'None' THEN 'MED'
		 ELSE 'LOW' END AS discount
FROM sales_transactions
GROUP BY discount, customer_category
ORDER BY total_spendings DESC;

--     - What is the average frequency of repeat purchases by customer category?
WITH repeat_customers as (SELECT COUNT(transaction_id)  , customer_name 
FROM sales_transactions
GROUP BY customer_name
HAVING COUNT(transaction_id)>1
)
,
CustomerTransactions AS (
    SELECT 
		st.customer_category as Customer_Category,st.Customer_Name, 
        st.Date,
        LAG(st.Date) OVER (PARTITION BY st.Customer_Name ORDER BY st.Date) AS Previous_Date
    FROM 
        sales_transactions st
    WHERE 
        st.Customer_Name IN (SELECT Customer_Name FROM repeat_Customers)
),
Purchasefrequency AS (
    SELECT
		Customer_Category,Customer_Name,Date,
        Previous_Date,
        DATE_PART('day', Date - Previous_Date) AS Interval_Days
    FROM 
        CustomerTransactions
    WHERE 
        Previous_Date IS NOT NULL
)
SELECT
   Customer_Category,
    AVG(Interval_Days) AS Avg_Repeat_Purchase_Frequency_Days
FROM 
    purchasefrequency
GROUP BY 
    Customer_Category
ORDER BY 
    Avg_Repeat_Purchase_Frequency_Days ASC;

-- 11. **Seasonal Sales Analysis**:
--     - What are the sales trends during peak seasons compared to off-peak periods?
WITH SeasonClassification AS (
    SELECT 
        Date,
        Transaction_ID,
        Total_Cost,
        CASE 
            WHEN EXTRACT(MONTH FROM Date) IN (11, 12, 1) THEN 'Peak'  
            WHEN EXTRACT(MONTH FROM Date) IN (6, 7, 8) THEN 'Peak'  
            ELSE 'Off-Peak' 
        END AS Season
    FROM 
        sales_transactions
),
SalesBySeason AS (
    SELECT
        Season,
        SUM(Total_Cost) AS Total_Sales,
        COUNT(Transaction_ID) AS Total_Transactions,
        AVG(Total_Cost) AS Average_Sales
    FROM 
        SeasonClassification GROUP BY Season
)
SELECT 
    Season,
    Total_Sales,
    Total_Transactions,
    Average_Sales
FROM 
    SalesBySeason
ORDER BY 
    Season DESC;  

--     - How do promotions affect sales during different seasons?
WITH SeasonClassification AS (
    SELECT 
        Date,
        Transaction_ID,
        Total_Cost,
        CASE 
            WHEN EXTRACT(MONTH FROM Date) IN (11, 12, 1) THEN 'Peak'  
            WHEN EXTRACT(MONTH FROM Date) IN (6, 7, 8) THEN 'Peak'  
            ELSE 'Off-Peak' 
        END AS Season,
        CASE 
            WHEN promotion <> 'None' THEN 'Promotion'
            ELSE 'No Promotion'
        END AS Promotion_Status
    FROM 
        sales_transactions
),
SalesBySeasonAndPromotion AS (
    SELECT
        Season,
        Promotion_Status,
        SUM(Total_Cost) AS Total_Sales,
        COUNT(Transaction_ID) AS Total_Transactions,
        AVG(Total_Cost) AS Average_Sales
    FROM 
        SeasonClassification
    GROUP BY 
        Season, Promotion_Status
)
SELECT 
    Season,Promotion_Status,
    Total_Sales,
    Total_Transactions,
    Average_Sales
FROM 
    SalesBySeasonAndPromotion
ORDER BY 
    Season DESC, Promotion_Status DESC;  

--     - How do sales trends during holiday seasons compare to sales trends during regular periods?
WITH HolidaySeasons AS (
   SELECT Date ,
   Transaction_id,
   Total_cost,
   CASE WHEN EXTRACT(month from date) IN (11,12,1) THEN 'Holiday'
   		ELSE 'Regular' END AS period
   FROM sales_transactions
)
SELECT period , AVG(total_cost) as Avg_sales_trend 
FROM HolidaySeasons
GROUP BY period
ORDER BY Avg_sales_trend DESC;

-- 12. **Sales Forecasting Preparation**:
--     - What are the historical trends in sales that could be used for forecasting future sales?
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', Date) AS Month,
        SUM(Total_Cost) AS Total_Sales,
        COUNT(Transaction_ID) AS Total_Transactions
    FROM 
        sales_transactions
    GROUP BY 
        DATE_TRUNC('month', Date)
    ORDER BY 
        Month
),
Yearlysalesgrowth AS (
	SELECT 
		EXTRACT(year from Month) AS year,
        SUM(Total_sales) AS yearly_Sales,
		LAG(SUM(total_sales)) OVER (ORDER BY EXTRACT(year from month)) AS previous_year_sales,
		(SUM(Total_Sales) - LAG(SUM(Total_Sales)) OVER (ORDER BY EXTRACT(YEAR FROM Month))) / LAG(SUM(Total_Sales)) OVER (ORDER BY EXTRACT(YEAR FROM Month)) * 100 AS Yearly_Growth_Rate
    FROM 
        MonthlySales
    GROUP BY 
        year
),
MovingAverageSales AS (
    SELECT
        Month,
        Total_Sales,
        AVG(Total_Sales) OVER (ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Three_Month_Moving_Avg
    FROM
        MonthlySales
)
SELECT
    m.Month,
    m.Total_Sales,
    ma.Three_Month_Moving_Avg,
    yg.Yearly_Growth_Rate
FROM 
    MonthlySales m
LEFT JOIN 
    MovingAverageSales ma ON m.Month = ma.Month
LEFT JOIN 
    YearlySalesGrowth yg ON EXTRACT(YEAR FROM m.Month) = yg.Year
ORDER BY 
    m.Month;
	
--     - How do different variables (e.g., season, promotion, discount) impact sales trends?
WITH SalesSegments AS (
    SELECT 
        CASE 
            WHEN EXTRACT(MONTH FROM Date) IN (11, 12, 1) THEN 'Holiday'
            WHEN EXTRACT(MONTH FROM Date) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Regular'
        END AS Season,
        CASE 
            WHEN promotion <> 'None' THEN 'Promotion'
            ELSE 'No Promotion'
        END AS Promotion_Status,
        CASE 
            WHEN discount_Applied = 'true' THEN 'Discount'
            ELSE 'No Discount'
        END AS Discount_Status,
        SUM(total_cost) AS Total_Sales,
        COUNT(transaction_id) AS Total_Transactions,
        AVG(total_cost) AS Average_Sales
    FROM 
        sales_transactions
    GROUP BY 
        CASE 
            WHEN EXTRACT(MONTH FROM Date) IN (11, 12, 1) THEN 'Holiday'
            WHEN EXTRACT(MONTH FROM Date) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Regular'
        END,
        CASE 
            WHEN promotion <> 'None' THEN 'Promotion'
            ELSE 'No Promotion'
        END,
        CASE 
            WHEN discount_Applied = 'true' THEN 'Discount'
            ELSE 'No Discount'
        END
)
SELECT 
    Season,
    Promotion_Status,
    Discount_Status,
    Total_Sales,
    Total_Transactions,
    Average_Sales
FROM 
    SalesSegments
ORDER BY 
    Season, Promotion_Status, Discount_Status;

--     - What are the leading indicators of future sales trends based on historical data?
SELECT 
    EXTRACT(YEAR FROM Date) AS Year,
    EXTRACT(MONTH FROM Date) AS Month,
    SUM(total_cost) AS Total_Sales
FROM 
    sales_transactions
GROUP BY 
    EXTRACT(YEAR FROM Date), 
    EXTRACT(MONTH FROM Date)
ORDER BY 
    Year, 
    Month;
SELECT 
    CASE 
        WHEN promotion <> 'None' THEN 'Promotion'
        ELSE 'No Promotion'
    END AS Promotion_Status,
    SUM(total_cost) AS Total_Sales,
    COUNT(transaction_id) AS Total_Transactions
FROM 
    sales_transactions
GROUP BY 
    Promotion_Status
ORDER BY 
    Total_Sales DESC;
SELECT 
    customer_category,
    AVG(total_cost) AS Average_Spending,
    COUNT(transaction_id) AS Total_Transactions
FROM 
    sales_transactions
GROUP BY 
    customer_category
ORDER BY 
    Average_Spending DESC;
SELECT 
    discount_applied,
    SUM(total_cost) AS Total_Sales,
    COUNT(transaction_id) AS Total_Transactions,
    AVG(total_cost) AS Average_Sale
FROM 
    sales_transactions
GROUP BY 
    discount_applied
ORDER BY 
    Total_Sales DESC;


-- 14. **Regional Sales Analysis**:
--     - What are the sales performance metrics for different cities?
SELECT 
	City,
	Customer_Category,
	SUM(total_cost) as Total_sales,
	AVG(total_cost) as Average_sales,
	COUNT(transaction_id) as No_Transactions,
	SUM(Total_Items) as Total_Items_sold
FROM sales_transactions
GROUP BY City , Customer_Category;
	
--     - What are the sales trends for high-performing versus low-performing regions?
WITH HighLowCities AS (
    SELECT
        city,
        SUM(total_cost) AS Total_Sales
    FROM
        sales_transactions
    GROUP BY
        city
),
RankedCities AS (
    SELECT
        city,
        Total_Sales,
        RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM
        HighLowCities
),
SelectedCities AS (
    SELECT
        city
    FROM
        RankedCities
    WHERE
        Sales_Rank = 1 
        OR Sales_Rank = (SELECT MAX(Sales_Rank) FROM RankedCities)
)
SELECT
    s.city,
    EXTRACT(YEAR FROM t.Date) AS Year,
    EXTRACT(MONTH FROM t.Date) AS Month,
    SUM(t.total_cost) AS Total_Sales
FROM
    sales_transactions t
JOIN
    SelectedCities s ON t.city = s.city
GROUP BY
    s.city,
    Year,
    Month
ORDER BY
    s.city,
    Year,
    Month;

-- 15. **Data Integrity Checks**:
--     - Are there any anomalies or outliers in the data that need to be addressed?
SELECT
    AVG(total_cost) AS Mean_Sales,
    STDDEV(total_cost) AS Std_Dev_Sales,
    MIN(total_cost) AS Min_Sales,
    MAX(total_cost) AS Max_Sales
FROM
    sales_transactions;
-- z score
WITH SalesStats AS (
    SELECT
        AVG(total_cost) AS Mean_Sales,
        STDDEV(total_cost) AS Std_Dev_Sales
    FROM
        sales_transactions
),
SalesWithZScore AS (
    SELECT
        transaction_id,
        total_cost,
        (total_cost - (SELECT Mean_Sales FROM SalesStats)) / (SELECT Std_Dev_Sales FROM SalesStats) AS Z_Score
    FROM
        sales_transactions
)
SELECT
    transaction_id,
    total_cost,
    Z_Score
FROM
    SalesWithZScore
WHERE
    ABS(Z_Score) > 3; 
-- no outlier
--Rolling mean & sd
WITH RollingStats AS (
    SELECT
        Date,
        total_cost,
        AVG(total_cost) OVER (ORDER BY Date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS Rolling_Mean,
        STDDEV(total_cost) OVER (ORDER BY Date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS Rolling_StdDev
    FROM
        sales_transactions
)
SELECT
    Date,
    total_cost,
    Rolling_Mean,
    Rolling_StdDev,
    (total_cost - Rolling_Mean) / Rolling_StdDev AS Z_Score
FROM
    RollingStats
WHERE
    ABS((total_cost - Rolling_Mean) / Rolling_StdDev) > 3; 

--     - How complete is the sales data for each month and year?

WITH RECURSIVE Calendar AS (
    SELECT MIN(EXTRACT(YEAR FROM Date)) AS Year, MIN(EXTRACT(MONTH FROM Date)) AS Month
    FROM sales_transactions
    UNION ALL
    SELECT
        CASE WHEN Month < 12 THEN Year ELSE Year + 1 END AS Year,
        CASE WHEN Month < 12 THEN Month + 1 ELSE 1 END AS Month
    FROM Calendar
    WHERE Year < EXTRACT(YEAR FROM CURRENT_DATE) OR (Year = EXTRACT(YEAR FROM CURRENT_DATE) AND Month <= EXTRACT(MONTH FROM CURRENT_DATE))
)
,
SalesData AS (
    SELECT
        EXTRACT(YEAR FROM Date) AS Year,
        EXTRACT(MONTH FROM Date) AS Month,
        COUNT(transaction_id) AS Number_of_Transactions
    FROM
        sales_transactions
    GROUP BY
        Year,
        Month
)
SELECT
    c.Year,
    c.Month,
    COALESCE(s.Number_of_Transactions, 0) AS Number_of_Transactions
FROM
    Calendar c
LEFT JOIN
    SalesData s ON c.Year = s.Year AND c.Month = s.Month
ORDER BY
    c.Year,
    c.Month;
SELECT
    Year,
    Month,
    CASE WHEN Number_of_Transactions = 0 THEN 'Missing Data'
         ELSE 'Data Present'
    END AS Data_Status
FROM
    (SELECT
        EXTRACT(YEAR FROM Date) AS Year,
        EXTRACT(MONTH FROM Date) AS Month,
        COUNT(transaction_id) AS Number_of_Transactions
    FROM
        sales_transactions
    GROUP BY
        Year,
        Month) AS MonthlyData
ORDER BY
    Year,
    Month;

