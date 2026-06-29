-- ============================================================================
-- TIER 2: AGGREGATION
-- QUERY 06: Customer Purchase Frequency Distribution
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Customer Loyalty team needs to understand the purchase frequency distribution 
-- (how many orders a customer places) to identify the percentage of one-time 
-- buyers versus loyal repeat buyers.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Repeat Purchase Rate, Customer Cohort Count by Lifetime Order Frequency.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    order_count,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM core.orders), 2) AS pct_of_active_base
FROM (
    SELECT 
        customer_id, 
        COUNT(order_id) AS order_count
    FROM core.orders
    GROUP BY customer_id
) customer_orders
GROUP BY order_count
ORDER BY order_count ASC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Approximately 27% of customers are one-time buyers, while 73% have ordered 
-- at least twice. This indicates strong product-market fit and brand loyalty, 
-- but reveals an opportunity to target the one-time buyers cohort with welcome 
-- discount coupons to secure their second order.
--
-- EXECUTIVE SUMMARY:
-- This query categorizes the active customer base by their total lifetime order 
-- count, computing the size and percentage of each buyer cohort. Isolating the size 
-- of the single-order cohort allows marketing teams to design automated campaigns 
-- that push single buyers into the highly profitable repeat buyer cohort.
-- ============================================================================
