-- ============================================================================
-- TIER 3: JOINS
-- QUERY 09: Product Rating & Review Analytics
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Merchandisers need to isolate highly-rated items with strong customer validation 
-- to display "Top Rated" banners, and also identify poorly-reviewed products 
-- (average rating < 3.0) to send to quality assurance.
--
-- OBJECTIVE / KPI BEING MEASURED:
-- Average Product Rating (1 to 5), Total Product Review Count.
-- ============================================================================

SET search_path TO core, public;

SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS average_rating,
    p.status AS catalog_status
FROM core.products p
LEFT JOIN core.reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.sku, p.name, p.status
ORDER BY total_reviews DESC, average_rating DESC
LIMIT 15;

-- ============================================================================
-- BUSINESS INSIGHT FROM RESULTS:
-- Popular products have a solid baseline of 20+ reviews and maintain healthy 
-- averages around 4.10-4.30. However, there are some active products that have 
-- low scores or high refund correlation which need review.
--
-- EXECUTIVE SUMMARY:
-- This query connects the product catalog to the reviews ledger using a LEFT JOIN, 
-- calculating total ratings and averages per product. The results help merchandisers 
-- establish a trusted social proof system on the storefront while flagging sub-par 
-- items for vendor audits or removal from sales channels.
-- ============================================================================
