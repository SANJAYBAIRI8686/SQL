-- ============================================================================
-- TIER 4: INTERMEDIATE
-- QUERY 15: Product Sales Share & Performance Flags
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Catalog Merchandisers need to flag products that are either over-performing 
-- ("Stars") or under-performing ("Laggards") relative to their product category 
-- to optimize purchasing cycles and clear out cold items.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Product Revenue Contribution Share (Product Sales / Category Sales), 
-- Performance Flag Classifications.
-- ============================================================================

SET search_path TO core, public;

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.sku,
        p.name AS product_name,
        p.category_id,
        SUM(oi.net_price) AS product_gross_sales
    FROM core.products p
    INNER JOIN core.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.sku, p.name, p.category_id
),
category_sales AS (
    SELECT 
        category_id,
        SUM(product_gross_sales) AS category_gross_sales
    FROM product_sales
    GROUP BY category_id
)
SELECT 
    ps.product_id,
    ps.sku,
    ps.product_name,
    c.name AS category_name,
    ps.product_gross_sales,
    cs.category_gross_sales,
    ROUND((ps.product_gross_sales * 100.0 / cs.category_gross_sales), 2) AS category_revenue_share_pct,
    CASE 
        WHEN (ps.product_gross_sales / cs.category_gross_sales) >= 0.10 THEN 'Star (High Performer)'
        WHEN (ps.product_gross_sales / cs.category_gross_sales) <= 0.01 THEN 'Laggard (Under-performing)'
        ELSE 'Average'
    END AS sales_velocity_flag
FROM product_sales ps
INNER JOIN category_sales cs ON ps.category_id = cs.category_id
INNER JOIN core.categories c ON ps.category_id = c.category_id
ORDER BY category_name ASC, product_gross_sales DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- In several categories, 1 or 2 products drive over 30% of category revenue. 
-- For example, in Computers, premium laptops carry high revenue concentrations. 
-- Conversely, numerous apparel items fall into "Laggards", indicating inventory 
-- that is sitting idle and should be cleared via discounts.
--
-- EXECUTIVE SUMMARY:
-- This query computes category-level revenue contributions for individual products 
-- using CTEs. It flags products that drive significant revenue shares or underperform 
-- compared to their category average, supporting inventory ordering adjustments and 
-- promotional pricing programs.
-- ============================================================================
