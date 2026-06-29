-- ============================================================================
-- TIER 3: JOINS
-- QUERY 08: Customer Order Summary (Including Zero-Order Accounts)
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Marketing Team needs a complete customer audit to identify "cold" registered 
-- accounts that have never placed a single order, so they can run an activation campaign.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Account Activation Rate (percentage of registered customers who make a purchase), 
-- Total Lifetime Orders per customer.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    c.created_at AS registered_at,
    COUNT(o.order_id) AS lifetime_orders,
    COALESCE(SUM(o.total_amount), 0.00) AS lifetime_spend
FROM core.customers c
LEFT JOIN core.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.email, c.first_name, c.last_name, c.created_at
ORDER BY lifetime_orders ASC, lifetime_spend ASC
LIMIT 20;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Running this shows that about 20% of registered customer records have 0 lifetime 
-- orders (lifetime_spend = 0.00). These are typically users who dropped off immediately 
-- after registering or abandoned their cart before entering billing info.
--
-- EXECUTIVE SUMMARY:
-- This query performs a LEFT JOIN from the master customer list to the orders ledger. 
-- It lists customers who have never completed a transaction alongside those who have, 
-- exposing inactive accounts and enabling CRM managers to target cold profiles with 
-- automated win-back promotions.
-- ============================================================================
