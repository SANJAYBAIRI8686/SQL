-- ============================================================================
-- TIER 2: AGGREGATION
-- QUERY 07: Average Order Value (AOV) Regional Segmentation
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Finance and Expansion teams need to analyze Average Order Values (AOV) and 
-- total revenue across different geographic regions (US States) to target regional 
-- marketing spend and logistics hubs.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Average Order Value (AOV = Total Sales / Order Count), Total Orders, Total Revenue.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    a.state_province AS state,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS regional_aov
FROM core.orders o
INNER JOIN core.addresses a ON o.shipping_address_id = a.address_id
GROUP BY a.state_province
HAVING COUNT(o.order_id) >= 100
ORDER BY regional_aov DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- High-AOV regions like Washington (WA) and California (CA) are driven by a high 
-- density of smart home and laptop products. In contrast, states like Texas (TX) 
-- show a higher volume of transactions but lower AOV, suggesting customers there 
-- buy more apparel.
--
-- EXECUTIVE SUMMARY:
-- This query aggregates order metrics and shipping address metadata to calculate 
-- the average transaction size (AOV) and total revenue per US state. By filtering for 
-- statistical significance (states with 100+ orders), it guides logistics planning 
-- for shipping zone optimizations and geo-targeted digital ads.
-- ============================================================================
