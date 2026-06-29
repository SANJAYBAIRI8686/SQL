-- ============================================================================
-- TIER 1: BASICS
-- QUERY 03: Products Below Minimum Inventory Threshold
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The warehouse management team needs to identify products where stock level is 
-- below safety thresholds to generate supplier replenishment purchase orders.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Stock Depletion rate & Safety Stock Threshold Warnings (quantity_on_hand < low_stock_threshold).
-- ============================================================================

SET search_path TO core, public;

SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    i.warehouse_code,
    i.quantity_on_hand,
    i.low_stock_threshold,
    (i.low_stock_threshold - i.quantity_on_hand) AS reorder_quantity
FROM core.products p
INNER JOIN core.inventory i ON p.product_id = i.product_id
WHERE i.quantity_on_hand < i.low_stock_threshold
  AND p.status = 'active'
ORDER BY i.quantity_on_hand ASC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Several active products are critically low, including fast-moving inventory items. 
-- For instance, Nova Portable T-Shirt (SKU NPT-1785) is down to 2 units in warehouse US-EAST-01, 
-- which will lead to stockouts within hours if not reordered.
--
-- EXECUTIVE SUMMARY:
-- This query scans the inventory ledger to list active products whose current stock 
-- levels are below their designated low-stock safety thresholds. Running this daily 
-- protects the e-commerce storefront against stockouts on high-demand SKUs and 
-- optimizes reorder workflows for logistics.
-- ============================================================================
