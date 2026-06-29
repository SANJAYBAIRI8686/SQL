-- ============================================================================
-- TIER 5: ADVANCED ANALYTICS
-- QUERY 08: Running Revenue Totals & 7-Day / 30-Day Moving Averages
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Financial analysts need to evaluate daily revenue, cumulative sales growth 
-- (running totals), and moving averages to smooth out daily transaction peaks 
-- (e.g. weekend spikes) and spot macro sales trends.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Daily Revenue, Cumulative Revenue (Running Total), and 7-day / 30-day Moving 
-- Average Revenue windows.
-- ============================================================================

SET search_path TO core, public;

WITH daily_sales AS (
    SELECT 
        ordered_at::DATE AS sales_date,
        SUM(total_amount) AS daily_revenue
    FROM core.orders
    WHERE status NOT IN ('cancelled', 'payment_failed')
    GROUP BY ordered_at::DATE
)
SELECT 
    sales_date,
    ROUND(daily_revenue, 2) AS daily_revenue,
    
    -- Running Total (Cumulative revenue from start of dataset)
    ROUND(SUM(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS running_total_revenue,
    
    -- 7-Day Simple Moving Average (SMA)
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7day,
    
    -- 30-Day Simple Moving Average (SMA)
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_30day
FROM daily_sales
ORDER BY sales_date DESC
LIMIT 60;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Comparing the 7-day and 30-day moving averages shows whether the business is 
-- decelerating or accelerating. The 7-day average fluctuates with marketing campaigns, 
-- whereas the 30-day average provides a reliable metric of our core run rate.
--
-- EXECUTIVE SUMMARY:
-- This query computes daily revenue and applies window function aggregations to 
-- calculate cumulative sales and rolling simple moving averages. The resulting dataset 
-- provides financial operators with smoothed charts that reveal underlying growth 
-- trajectories and remove high-frequency weekly noise.
-- ============================================================================
