-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 01: Customers with Above-Average Order Values
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Marketing team wants to identify high-spending customer profiles whose 
-- average order value exceeds the overall platform average order value (AOV). 
-- These users will be added to a targeted "High-Spender Catalog" campaign.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Customer AOV vs. Global Platform AOV.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.total_amount), 2) AS customer_aov,
    ROUND((SELECT AVG(total_amount) FROM core.orders), 2) AS global_platform_aov,
    ROUND(AVG(o.total_amount) - (SELECT AVG(total_amount) FROM core.orders), 2) AS aov_difference
FROM core.customers c
INNER JOIN core.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.email, c.first_name, c.last_name
HAVING AVG(o.total_amount) > (SELECT AVG(total_amount) FROM core.orders)
ORDER BY customer_aov DESC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Customers in this segment typically purchase tech items (laptops, monitors) 
-- rather than low-cost accessories. Adding them to high-ticket cross-selling 
-- campaigns will yield higher conversions compared to generic promotions.
--
-- EXECUTIVE SUMMARY:
-- This query uses a subquery in the HAVING clause to identify customers whose 
-- personal Average Order Value exceeds the company-wide average. Isolating this 
-- cohort helps marketing teams optimize ad budgets by focusing premium campaigns 
-- on proven high-spending buyers.
-- ============================================================================
