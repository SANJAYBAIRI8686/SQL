-- ============================================================================
-- TIER 3: JOINS
-- QUERY 11: Multi-Warehouse Inventory Distribution Audit
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Inventory Managers need a side-by-side stock audit comparing quantities 
-- available on hand in US-EAST-01 vs US-WEST-01 warehouses to evaluate if stock 
-- is balanced properly across regions.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Regional Inventory Balance, Reorder Deficit, and Stock Distribution.
-- ============================================================================

SET search_path TO core, public;

-- We use a self-join/conditional aggregate style or UNION to combine records 
-- for comparison of warehouse levels.
SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    COALESCE(SUM(CASE WHEN i.warehouse_code = 'US-EAST-01' THEN i.quantity_on_hand END), 0) AS east_qty,
    COALESCE(SUM(CASE WHEN i.warehouse_code = 'US-WEST-01' THEN i.quantity_on_hand END), 0) AS west_qty,
    ABS(
        COALESCE(SUM(CASE WHEN i.warehouse_code = 'US-EAST-01' THEN i.quantity_on_hand END), 0) - 
        COALESCE(SUM(CASE WHEN i.warehouse_code = 'US-WEST-01' THEN i.quantity_on_hand END), 0)
    ) AS stock_skew
FROM core.products p
INNER JOIN core.inventory i ON p.product_id = i.product_id
WHERE p.status = 'active'
GROUP BY p.product_id, p.sku, p.name
ORDER BY stock_skew DESC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Large skews (e.g. high stock in East but zero in West) force shipments to cross 
-- the country, increasing carrier costs and delivery times. High skew SKUs like 
-- laptops need split-shipment inbound purchasing to rebalance stock.
--
-- EXECUTIVE SUMMARY:
-- This query evaluates product quantities on hand across distinct physical warehouses, 
-- calculating the absolute skew between East and West Coast hubs. The resulting skew 
-- audit identifies inventory imbalances, helping supply chain teams optimize transfer 
-- orders and reduce cross-zone shipping surcharges.
-- ============================================================================
