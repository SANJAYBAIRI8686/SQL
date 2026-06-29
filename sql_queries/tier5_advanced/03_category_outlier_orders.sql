-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 03: Orders Exceeding Category Quantity Averages (Outliers)
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Fraud and Risk operations teams need to identify order line items that have 
-- unusually high quantities (outliers) compared to the average quantity purchased 
-- within that product's category. These could indicate merchant reseller activity, 
-- script-buy attacks, or quantity input errors.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Order Item Quantity Deviation (Line Quantity vs. Category Average Quantity).
-- ============================================================================

SET search_path TO core, public;

SELECT 
    oi.order_id,
    oi.product_id,
    p.sku,
    p.name AS product_name,
    c.name AS category_name,
    oi.quantity AS ordered_quantity,
    ROUND(cat_avg.avg_category_quantity, 2) AS category_average_quantity,
    ROUND((oi.quantity - cat_avg.avg_category_quantity), 2) AS quantity_variance
FROM core.order_items oi
INNER JOIN core.products p ON oi.product_id = p.product_id
INNER JOIN core.categories c ON p.category_id = c.category_id
INNER JOIN (
    -- Subquery computing the baseline average item quantity per category
    SELECT 
        p2.category_id, 
        AVG(oi2.quantity) AS avg_category_quantity
    FROM core.order_items oi2
    INNER JOIN core.products p2 ON oi2.product_id = p2.product_id
    GROUP BY p2.category_id
) cat_avg ON p.category_id = cat_avg.category_id
WHERE oi.quantity > (cat_avg.avg_category_quantity * 3.0) -- Flag items ordered at > 3x the category average
ORDER BY ordered_quantity DESC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Orders flagged by this query typically feature quantities of 5+ items in categories 
-- like Computers & Tablets, where the average purchase quantity is 1.05. This indicates 
-- B2B bulk purchases or pricing exploit attempts that need post-checkout inspection.
--
-- EXECUTIVE SUMMARY:
-- This query identifies transactional outliers by comparing line-item quantities 
-- against aggregate category averages. By flagging orders that exceed three times 
-- the category baseline, it provides a simple security gate to audit bulk-reselling or 
-- system-exploit checkout profiles.
-- ============================================================================
