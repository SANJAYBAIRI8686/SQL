-- ============================================================================
-- TIER 4: INTERMEDIATE
-- QUERY 12: Customer Value Segmentation Tiers (LTV)
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The CRM team needs to classify customers into lifetime value (LTV) tiers 
-- (High, Medium, Low) to target VIPs with exclusive concierge services and 
-- prioritize loyalty points allocation.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Customer Lifetime Value (LTV = Sum of Order Totals), Customer Segment Size, 
-- and Segment Revenue Contribution.
-- ============================================================================

SET search_path TO core, public;

WITH customer_spend AS (
    SELECT 
        c.customer_id,
        c.email,
        c.first_name || ' ' || c.last_name AS customer_name,
        COALESCE(SUM(o.total_amount), 0.00) AS total_spent,
        COUNT(o.order_id) AS order_count
    FROM core.customers c
    LEFT JOIN core.orders o ON c.customer_id = o.customer_id AND o.status NOT IN ('cancelled', 'payment_failed')
    GROUP BY c.customer_id, c.email, c.first_name, c.last_name
)
SELECT 
    CASE 
        WHEN total_spent >= 5000.00 THEN '1. VIP (High Value)'
        WHEN total_spent >= 1000.00 AND total_spent < 5000.00 THEN '2. Core (Medium Value)'
        WHEN total_spent > 0.00 AND total_spent < 1000.00 THEN '3. Occasional (Low Value)'
        ELSE '4. Inactive'
    END AS customer_tier,
    COUNT(customer_id) AS customer_count,
    ROUND(SUM(total_spent), 2) AS total_segment_spend,
    ROUND(AVG(total_spent), 2) AS average_spend_per_customer,
    ROUND(SUM(total_spent) * 100.0 / (SELECT SUM(total_amount) FROM core.orders WHERE status NOT IN ('cancelled', 'payment_failed')), 2) AS revenue_share_pct
FROM customer_spend
GROUP BY 1
ORDER BY customer_tier ASC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- The results reflect a classic Pareto distribution (80/20 rule). The VIP tier, 
-- although representing a small percentage of customer volume, accounts for a 
-- substantial majority of total platform revenue, highlighting the importance of VIP retention.
--
-- EXECUTIVE SUMMARY:
-- This query uses a Common Table Expression (CTE) and conditional CASE expressions 
-- to partition our customer base into distinct lifetime spend segments. It reveals 
-- the relative revenue contribution of VIPs, Core, and Occasional shoppers, 
-- supporting CRM loyalty initiatives and targeted promotions.
-- ============================================================================
