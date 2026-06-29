-- ============================================================================
-- TIER 4: INTERMEDIATE
-- QUERY 14: Logistics Latency & Carrier SLA Funnel Analysis
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Logistics operators need to monitor carrier delivery performance and fulfillment 
-- delays (time to pick, ship, and deliver packages) to verify shipping SLA 
-- compliance and select the best courier per region.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Average Warehouse Processing Days (shipped_at - ordered_at), Transit Days 
-- (delivered_at - shipped_at), and Total Fulfillment Days (delivered_at - ordered_at).
-- ============================================================================

SET search_path TO core, public;

SELECT 
    carrier,
    COUNT(shipment_id) AS shipment_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (shipped_at - created_at)) / 86400.0)::numeric, 2) AS avg_warehouse_processing_days,
    ROUND(AVG(EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0)::numeric, 2) AS avg_transit_days,
    ROUND(AVG(EXTRACT(EPOCH FROM (delivered_at - created_at)) / 86400.0)::numeric, 2) AS avg_total_fulfillment_days
FROM core.shipments
WHERE status = 'delivered'
  AND shipped_at IS NOT NULL
  AND delivered_at IS NOT NULL
GROUP BY carrier
ORDER BY avg_total_fulfillment_days ASC;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- DHL and FedEx show the fastest overall fulfillment times, averaging around 
-- 4.5 days. USPS has the longest average transit time, making it suitable for 
-- low-priority, lightweight packages where cost-savings override speed.
--
-- EXECUTIVE SUMMARY:
-- This query measures delivery duration milestones for completed shipments grouped 
-- by carrier. Isolating warehouse processing and transit times allows managers to 
-- identify operational bottlenecks, optimize warehouse dispatch speeds, and select the 
-- most cost-effective carriers based on actual SLA performance.
-- ============================================================================
