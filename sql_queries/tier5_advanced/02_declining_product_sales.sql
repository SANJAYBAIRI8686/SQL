-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 02: Products with Declining Sales Trends MoM
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Merchandisers need to flag products that have experienced consecutive 
-- Month-over-Month (MoM) revenue declines to clear stock via promotions or 
-- discontinue poor performing lines.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Consecutive Monthly Revenue Decline (Revenue(m) < Revenue(m-1) < Revenue(m-2)).
-- ============================================================================

SET search_path TO core, public;

WITH product_monthly_sales AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.ordered_at)::DATE AS sales_month,
        SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS revenue
    FROM core.order_items oi
    INNER JOIN core.orders o ON oi.order_id = o.order_id
    GROUP BY oi.product_id, DATE_TRUNC('month', o.ordered_at)
),
sales_lags AS (
    SELECT 
        product_id,
        sales_month,
        revenue,
        LAG(revenue, 1) OVER (PARTITION BY product_id ORDER BY sales_month) AS prev_month_revenue,
        LAG(revenue, 2) OVER (PARTITION BY product_id ORDER BY sales_month) AS two_months_ago_revenue
    FROM product_monthly_sales
)
SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    sl.sales_month AS evaluation_month,
    ROUND(sl.revenue, 2) AS current_month_sales,
    ROUND(sl.prev_month_revenue, 2) AS prev_month_sales,
    ROUND(sl.two_months_ago_revenue, 2) AS two_months_ago_sales,
    ROUND(((sl.revenue - sl.two_months_ago_revenue) * 100.0 / NULLIF(sl.two_months_ago_revenue, 0)), 2) AS two_month_decline_pct
FROM sales_lags sl
INNER JOIN core.products p ON sl.product_id = p.product_id
WHERE sl.revenue < sl.prev_month_revenue 
  AND sl.prev_month_revenue < sl.two_months_ago_revenue
  AND sl.sales_month = (SELECT DATE_TRUNC('month', MAX(ordered_at)) - INTERVAL '1 month' FROM core.orders)
ORDER BY two_month_decline_pct ASC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Products displaying consecutive declines are often seasonal items reaching 
-- the end of their peak demand cycle (e.g. winter apparel in early spring). 
-- This analysis triggers automated promotional discounts before item storage 
-- cost exceeds profit potential.
--
-- EXECUTIVE SUMMARY:
-- This query uses a CTE with the LAG window function to identify products whose 
-- gross sales have dropped for two consecutive months. By tracking these downward 
-- sales trajectories, inventory managers can take proactive steps to prevent dead 
-- stock accumulation.
-- ============================================================================
