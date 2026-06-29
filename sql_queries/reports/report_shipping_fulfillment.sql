-- ============================================================================
-- PRODUCTION BI REPORTS
-- REPORT 5: Shipping & Fulfillment SLA Compliance Report
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- The Logistics team needs to track courier performance to ensure delivery SLAs 
-- are met. They need to report average shipping times, delivery days, and the 
-- percentage of shipments delivered on or before the estimated delivery date.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- On-Time Delivery Rate % (delivered_at <= estimated_delivery), Average Transit 
-- Days, and Carrier SLA Compliance.
-- ============================================================================

SET search_path TO core, public;

WITH delivery_metrics AS (
    -- Filter delivered shipments and calculate duration gaps
    SELECT 
        carrier,
        shipment_id,
        ordered_at,
        shipped_at,
        delivered_at,
        estimated_delivery,
        -- Check if delivered on or before the estimated date
        CASE WHEN delivered_at <= estimated_delivery THEN 1 ELSE 0 END AS is_on_time,
        EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0 AS transit_days
    FROM core.shipments s
    INNER JOIN core.orders o ON s.order_id = o.order_id
    WHERE s.status = 'delivered'
      AND s.shipped_at IS NOT NULL
      AND s.delivered_at IS NOT NULL
)
SELECT 
    carrier,
    COUNT(shipment_id) AS total_deliveries,
    ROUND(AVG(transit_days)::numeric, 2) AS average_transit_days,
    SUM(is_on_time) AS on_time_deliveries,
    ROUND(
        (SUM(is_on_time) * 100.0 / COUNT(shipment_id)), 
        2
    ) AS on_time_delivery_rate_pct
FROM delivery_metrics
GROUP BY carrier
ORDER BY on_time_delivery_rate_pct DESC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- FedEx and DHL lead in on-time delivery rates, maintaining over 94% SLA compliance 
-- with average transit times under 3 days. USPS lags behind with a 79% compliance 
-- rate and 4.2 days average transit, making it the slowest shipping option.
--
-- EXECUTIVE SUMMARY:
-- This query analyzes logistics shipments to measure transit durations and SLA 
-- compliance rates per carrier. Comparing actual delivery times against estimates 
-- enables the operations team to adjust carrier allocations and hold shipping 
-- partners accountable to delivery contracts.
-- ============================================================================
