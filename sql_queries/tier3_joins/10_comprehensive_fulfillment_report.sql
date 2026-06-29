-- ============================================================================
-- TIER 3: JOINS
-- QUERY 10: Comprehensive Order Fulfillment & Logistics Report
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Supply Chain Operations requires a real-time fulfillment queue report showing 
-- customer information, order totals, shipping carrier, and delivery status 
-- to identify bottlenecked shipments.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Order Dispatch Rate, Shipment Lead Times, and Open Carrier Backlog.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    o.order_id,
    o.ordered_at,
    o.status AS order_status,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    a.city,
    a.state_province AS state,
    o.total_amount,
    s.carrier,
    s.tracking_number,
    s.status AS shipment_status,
    s.shipped_at
FROM core.orders o
INNER JOIN core.customers c ON o.customer_id = c.customer_id
INNER JOIN core.addresses a ON o.shipping_address_id = a.address_id
LEFT JOIN core.shipments s ON o.order_id = s.order_id
WHERE o.status IN ('processing', 'shipped')
ORDER BY o.ordered_at ASC
LIMIT 20;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Sorting older orders first reveals processing orders that have not yet had a 
-- shipment label generated, indicating potential warehouse picking delays or 
-- inventory discrepancies that require immediate warehouse manager attention.
--
-- EXECUTIVE SUMMARY:
-- This query performs a multi-table JOIN across orders, customers, addresses, and 
-- shipments. It outputs a consolidated logistics dashboard of orders in transit or 
-- picking stages, allowing operators to monitor carrier performance and identify 
-- delayed packages.
-- ============================================================================
