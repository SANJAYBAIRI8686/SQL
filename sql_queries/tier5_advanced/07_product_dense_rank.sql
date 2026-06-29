-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 07: Top Products by Sales Volume (DENSE_RANK)
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Merchandisers need an absolute list ranking products by total quantity sold 
-- without skipping rank indices (i.e. dense ranking) to determine bestsellers for 
-- promotional carousels.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Product Quantity Sales Rank (using DENSE_RANK() window function).
-- ============================================================================

SET search_path TO core, public;

WITH product_volumes AS (
    SELECT 
        p.product_id,
        p.sku,
        p.name AS product_name,
        c.name AS category_name,
        COALESCE(SUM(oi.quantity), 0) AS total_units_sold
    FROM core.products p
    INNER JOIN core.categories c ON p.category_id = c.category_id
    LEFT JOIN core.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.sku, p.name, c.name
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_units_sold DESC) AS product_sales_rank,
    product_id,
    sku,
    product_name,
    category_name,
    total_units_sold
FROM product_volumes
ORDER BY product_sales_rank ASC
LIMIT 20;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Low-cost items like Smart Light Bulbs and T-Shirts lead absolute volume ranks. 
-- However, when dense-ranked, items with identical unit sales share the same rank, 
-- giving a clear picture of tier-1 volume leaders vs slow-moving inventory.
--
-- EXECUTIVE SUMMARY:
-- This query aggregates total units sold per product and ranks them using the 
-- DENSE_RANK() window function to ensure consecutive index rankings. This bestseller 
-- hierarchy enables merchandisers to optimize category pages and highlight high-demand 
-- goods on the homepage.
-- ============================================================================
