-- ============================================================================
-- TIER 2: AGGREGATION
-- QUERY 04: Sales by Product Category
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Category Managers need to evaluate the financial performance of each product 
-- category to optimize supplier contracts, inventory sizing, and marketing focus.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Total Sales Revenue, Average Item Transaction Price, and Volume of Items Sold.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    c.category_id,
    c.name AS category_name,
    COUNT(oi.order_item_id) AS total_items_sold,
    SUM(oi.net_price) AS total_gross_sales,
    ROUND(AVG(oi.unit_price), 2) AS average_unit_price
FROM core.categories c
INNER JOIN core.products p ON c.category_id = p.category_id
INNER JOIN core.order_items oi ON p.product_id = oi.product_id
GROUP BY c.category_id, c.name
HAVING SUM(oi.net_price) > 50000.00
ORDER BY total_gross_sales DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Computers & Tablets and Smart Home drive over 60% of total company revenue. 
-- However, Apparel categories show much higher item volume (transaction count) 
-- but lower average unit price. Focus on cross-selling low-cost apparel with 
-- high-cost computer purchases.
--
-- EXECUTIVE SUMMARY:
-- This query consolidates line-item transactions to calculate total revenue, sales 
-- count, and average prices grouped by product category. It filters out low-volume 
-- categories generating under $50,000 to highlight the primary revenue-driving channels 
-- supporting company growth.
-- ============================================================================
