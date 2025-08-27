-- Time-Series analysis:
-- Change over  Time

-- Total sales by year and month
SELECT 
    EXTRACT(YEAR FROM order_date::date) AS order_year,
    EXTRACT(MONTH FROM order_date::date) AS order_month,
    TO_CHAR(order_date::date, 'Mon') AS month_name,
    SUM(sales_amount) AS total_sales,
    COUNT(order_number) AS orders_placed
FROM gold.fact_sales
GROUP BY 
    EXTRACT(YEAR FROM order_date::date),
    EXTRACT(MONTH FROM order_date::date),
    TO_CHAR(order_date::date, 'Mon')
ORDER BY order_year, order_month;


-- No.of Orders by month
SELECT 
    DATE_TRUNC('month', order_date::date) AS order_month,  -- first day of the month
    --SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT order_number) AS orders_placed
FROM gold.fact_sales
GROUP BY DATE_TRUNC('month', order_date::date)
ORDER BY order_month;

-- Cummulative analysis:

-- Total sales per month and running total of sales over time(by year)

SELECT
    date_period,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY DATE_TRUNC('year', date_period::date) ORDER BY date_period)
FROM 
    (SELECT
        DATE_TRUNC('month', order_date::date) AS date_period,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    GROUP BY DATE_TRUNC('month', order_date::date)
    )

-- Performance Analysis:

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date::date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        EXTRACT(YEAR FROM f.order_date::date),
        p.product_name
)

SELECT
    order_year,
    product_name,
    current_sales,
    ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 2) AS avg_sales,
    ROUND(current_sales - AVG(current_sales) OVER (PARTITION BY product_name), 2) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    -- Year-over-Year Analysis
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- Data Segmentation:

/*Segment products into cost ranges and count how many products fall into each segment*/
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH customer_spending AS (
    SELECT c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date::date) AS first_order,
        MAX(f.order_date::date) AS last_order,
        -- Calculate lifespan in months
        (
            DATE_PART(
                'year',
                AGE(MAX(f.order_date::date), MIN(f.order_date::date))
            ) * 12 + DATE_PART(
                'month',
                AGE(MAX(f.order_date::date), MIN(f.order_date::date))
            )
        )::int AS lifespan
    FROM gold.fact_sales f
        LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
        SELECT customer_key,
            CASE
                WHEN lifespan >= 12
                AND total_spending > 5000 THEN 'VIP'
                WHEN lifespan >= 12
                AND total_spending <= 5000 THEN 'Regular'
                ELSE 'New'
            END AS customer_segment
        FROM customer_spending
    ) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;

-- Part-to-whole Analysis:

WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND(total_sales  / SUM(total_sales) OVER () * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

