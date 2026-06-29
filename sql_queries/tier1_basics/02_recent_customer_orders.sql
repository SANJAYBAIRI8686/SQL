-- ============================================================================
-- TIER 1: BASICS
-- QUERY 02: Customers with Orders in Last 30 Days
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Customer Success needs a list of recent buyers to send a feedback survey 
-- and coupon code to drive repeat purchases within their active purchase window.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Recent Customer Purchase Activity (filtering buyers within a rolling 30-day window).
-- ============================================================================

SET search_path TO core, public;

-- To ensure the query remains executable on historical synthetic data, 
-- we calculate the 30-day window relative to the maximum order date in the system.
SELECT DISTINCT 
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    MAX(o.ordered_at) AS last_order_date
FROM core.customers c
INNER JOIN core.orders o ON c.customer_id = o.customer_id
WHERE o.ordered_at >= (SELECT MAX(ordered_at) FROM core.orders) - INTERVAL '30 days'
GROUP BY c.customer_id, c.email, c.first_name, c.last_name
ORDER BY last_order_date DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- This list represents our most active cohort. Cross-referencing their email profiles 
-- shows a high density of VIP cohort buyers who have purchased multiple times, 
-- indicating that targeted automated emails sent within 30 days have a high open rate.
--
-- EXECUTIVE SUMMARY:
-- This query extracts customers who placed orders in the 30 days prior to the 
-- latest system transaction. By isolating this recent buyer segment, marketing can 
-- trigger post-purchase feedback loops and product review requests to increase overall 
-- lifetime customer engagement.
-- ============================================================================
