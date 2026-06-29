-- ============================================================================
-- PRODUCTION BI REPORTS
-- REPORT 7: Geographic Performance & Customer Density Report
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Expansion and Logistics teams require a geographic report detailing 
-- customer density, total revenue, and average shipping costs per state to identify 
-- where to construct local micro-fulfillment centers.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Customer Density (Unique Customers), Total State Revenue, and Average Shipping 
-- Cost per order.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    a.state_province AS state,
    a.country,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.shipping_amount), 2) AS average_shipping_cost,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT c.customer_id), 2) AS average_spend_per_customer
FROM core.customers c
INNER JOIN core.addresses a ON c.customer_id = a.customer_id
INNER JOIN core.orders o ON o.customer_id = c.customer_id
WHERE o.status NOT IN ('cancelled', 'payment_failed')
GROUP BY a.state_province, a.country
HAVING COUNT(o.order_id) >= 50
ORDER BY total_revenue DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- California (CA) and Texas (TX) contain the highest customer density and generate 
-- the bulk of sales. However, Washington (WA) has the highest average spend per 
-- customer, representing a highly concentrated premium buyer cohort that justifies 
-- localized catalog merchandising focus.
--
-- EXECUTIVE SUMMARY:
-- This query details regional performance by mapping customer density, transaction 
-- volume, and shipping costs to US states. The report filters for statistical 
-- significance, highlighting top revenue states to inform logistics infrastructure 
-- expansion and regional marketing spends.
-- ============================================================================
