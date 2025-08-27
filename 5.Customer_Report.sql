/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.customer_report
-- =============================================================================

CREATE OR REPLACE VIEW gold.customer_report AS

/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
WITH base_table AS (
SELECT
    s.product_key,
    s.order_number,
    s.sales_amount,
    s.quantity,
    s.order_date,
    c.customer_key,
    c.customer_number,
    EXTRACT(YEAR FROM AGE(NOW(), c.birthdate::date)) AS age,
    CONCAT(c.first_name, ' ',c.last_name) AS customer_name
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key = s.customer_key
WHERE s.order_date IS NOT NULL
)

/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
,customer_aggregated AS (
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(product_key) AS total_products,
    (DATE_PART('year', MAX(order_date::date)) - DATE_PART('year', MIN(order_date::date))) * 12 +
    (DATE_PART('month', MAX(order_date::date)) - DATE_PART('month', MIN(order_date::date))) AS lifespan,
    MAX(order_date::date) AS last_order_date
FROM base_table
GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age
)


SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'  
        ELSE 'New'
    END AS customer_segment,
	CASE  
        WHEN age < 20 THEN 'Under 20'
        WHEN age between 20 and 29 THEN '20-29'
        WHEN age between 30 and 39 THEN '30-39'
        WHEN age between 40 and 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    --Recency
    (EXTRACT(YEAR FROM AGE(NOW(), last_order_date::date)) * 12 +
    EXTRACT(MONTH FROM AGE(NOW(), last_order_date::date))) AS recency_months,
    -- Compuate average order value (AVO)
    CASE WHEN total_sales = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    -- Compuate average monthly spend
    CASE WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend
FROM customer_aggregated
