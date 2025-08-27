-- 1) Database exploaration

SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold';

SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_products' ;

SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_customers' ;

SELECT column_name, data_type FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'fact_sales' ;

-- 2) Dimension Exploration

SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3;

SELECT DISTINCT country FROM gold.dim_customers;

-- 3) Date exploration

SELECT 
    MIN(order_date::date) AS start_order_date,
    MAX(order_date::date) AS latest_order_date,
    EXTRACT(YEAR FROM MAX(order_date::date)) - EXTRACT(YEAR FROM MIN(order_date::date)) AS total_years
FROM gold.fact_sales;

-- What is the age of the customers

SELECT
    EXTRACT(YEAR FROM (AGE(CURRENT_DATE, MAX(birthdate::date)))) youngest_age,
    EXTRACT(YEAR FROM (AGE(CURRENT_DATE, MIN(birthdate::date)))) oldest_age
FROM gold.dim_customers

-- 4) Measures Exploration
SELECT * FROM gold.fact_sales;

-- Find the total sales
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
-- How many items are sold
SELECT 'Total Items Sold' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
-- Average selling price
SELECT 'Avg Selling Price' AS measure_name, ROUND(AVG(sales_amount), 2) AS measure_value FROM gold.fact_sales
UNION ALL
-- Total number of orders
SELECT 'Total Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
-- Total number of customers
SELECT 'Total No.of Customers' AS measure_name, COUNT(customer_id) AS measure_value FROM gold.dim_customers
UNION ALL
-- Total number of products
SELECT 'Total No.of Products' AS measure_name, COUNT(*) AS measure_value FROM gold.dim_products


-- Total number of customers that has placed an order
SELECT ''COUNT(DISTINCT customer_key) FROM gold.fact_sales


