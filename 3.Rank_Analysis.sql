-- Top 5 high revenue generated products
SELECT *
FROM
    (SELECT
        p.product_name,
        SUM(s.sales_amount) AS total_revenue,
        RANK() OVER(ORDER BY SUM(s.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON p.product_key = s.product_key
    GROUP BY p.product_name
    ) t
WHERE rank_products <=5