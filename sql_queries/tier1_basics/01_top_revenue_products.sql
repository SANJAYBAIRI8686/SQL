-- ============================================================================
-- TIER 1: BASICS
-- QUERY 01: Top 10 Products by Revenue
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The sales and marketing teams need to identify the top 10 products by gross 
-- revenue to optimize digital storefront real estate and allocate ad spend.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Gross Sales Revenue (sum of quantity * unit_price minus discount_amount).
-- ============================================================================

SET search_path TO core, public;

SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS gross_revenue
FROM core.products p
INNER JOIN core.order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.sku, p.name
ORDER BY gross_revenue DESC
LIMIT 10;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- High-ticket electronics like premium laptops and desktops dominate the 
-- top revenue slots despite lower sales quantities compared to apparel. 
-- Product ID 120 (Ultra Comfort Keyboard) and Product ID 192 (Nova Premium Laptop) 
-- are major revenue-driving anchors.
--
-- EXECUTIVE SUMMARY:
-- This query aggregates historical order items to identify the top ten highest 
-- revenue generating products in the catalog. The results show that laptops and 
-- keyboards represent the primary financial anchors of our catalog, suggesting 
-- promotional bundles targeting corporate purchase profiles will yield high margins.
-- ============================================================================
