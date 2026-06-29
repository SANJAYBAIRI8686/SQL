-- ============================================================================
-- TIER 4: INTERMEDIATE
-- QUERY 16: Return Rate & Refund Leakage Analysis
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The QA and Finance teams need to track product returns and identify items with 
-- high refund rates (refund leakage) relative to gross sales, indicating potential 
-- manufacturing defects or inaccurate sizing.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Refund Leakage Rate (Refunds / Gross Sales), Total Return Count, and Refunded Cash.
-- ============================================================================

SET search_path TO core, public;

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.sku,
        p.name AS product_name,
        SUM(oi.net_price) AS gross_sales,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM core.products p
    INNER JOIN core.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.sku, p.name
),
product_returns AS (
    SELECT 
        oi.product_id,
        COUNT(r.return_id) AS total_returns,
        SUM(r.refunded_amount) AS total_refunded
    FROM core.order_items oi
    INNER JOIN core.returns r ON oi.order_item_id = r.order_item_id
    GROUP BY oi.product_id
)
SELECT 
    ps.product_id,
    ps.sku,
    ps.product_name,
    ps.gross_sales,
    COALESCE(pr.total_returns, 0) AS return_count,
    COALESCE(pr.total_refunded, 0.00) AS total_refunded_cash,
    ROUND(
        (COALESCE(pr.total_refunded, 0.00) * 100.0 / ps.gross_sales), 
        2
    ) AS refund_leakage_pct
FROM product_sales ps
LEFT JOIN product_returns pr ON ps.product_id = pr.product_id
WHERE ps.gross_sales > 10000.00
ORDER BY refund_leakage_pct DESC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Certain clothing items and accessories show high return rates (~8-10% of revenue), 
-- which is typical for sizing mismatches. However, if electronic products exceed 
-- a 3% refund rate, it suggests a defective batch or poor description that should 
-- trigger product inspection.
--
-- EXECUTIVE SUMMARY:
-- This query analyzes returns and refunds at the product level, calculating the 
-- ratio of refunded cash to total gross sales. By isolating items with high refund 
-- leakage, operations can investigate suppliers or modify size charts to protect 
-- company profit margins.
-- ============================================================================
