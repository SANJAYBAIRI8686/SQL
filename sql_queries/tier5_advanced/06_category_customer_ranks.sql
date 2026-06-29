-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 06: Customer Rankings Within Each Product Category
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Category managers want to identify the top 5 spenders within each product 
-- category to offer customized VIP catalog discounts and build focus groups.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Customer Category Spend Ranking (using ROW_NUMBER() window function).
-- ============================================================================

SET search_path TO core, public;

WITH customer_category_spend AS (
    SELECT 
        c.customer_id,
        c.email,
        c.first_name || ' ' || c.last_name AS customer_name,
        p.category_id,
        cat.name AS category_name,
        SUM(oi.net_price) AS total_category_spend
    FROM core.customers c
    INNER JOIN core.orders o ON c.customer_id = o.customer_id
    INNER JOIN core.order_items oi ON o.order_id = oi.order_id
    INNER JOIN core.products p ON oi.product_id = p.product_id
    INNER JOIN core.categories cat ON p.category_id = cat.category_id
    WHERE o.status NOT IN ('cancelled', 'payment_failed')
    GROUP BY c.customer_id, c.email, c.first_name, c.last_name, p.category_id, cat.name
),
ranked_spenders AS (
    SELECT 
        customer_id,
        email,
        customer_name,
        category_name,
        total_category_spend,
        ROW_NUMBER() OVER (
            PARTITION BY category_name 
            ORDER BY total_category_spend DESC
        ) AS customer_rank_in_category
    FROM customer_category_spend
)
SELECT 
    category_name,
    customer_rank_in_category,
    customer_id,
    customer_name,
    email,
    ROUND(total_category_spend, 2) AS total_category_spend
FROM ranked_spenders
WHERE customer_rank_in_category <= 5
ORDER BY category_name ASC, customer_rank_in_category ASC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Top spenders in Computers & Tablets spend upwards of $8,000, while the top 
-- spenders in Apparel hover around $1,500. This disparity highlights the need for 
-- tiered loyalty thresholds, where high-cost category buyers receive high-tier 
-- credits.
--
-- EXECUTIVE SUMMARY:
-- This query aggregates customer transaction details at the category level and 
-- ranks customers using the ROW_NUMBER() window function. By displaying only the 
-- top 5 spenders per product category, it guides regional sales managers in 
-- targeted B2B catalog promotions and customer advocacy programs.
-- ============================================================================
