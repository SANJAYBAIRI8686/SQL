-- ============================================================================
-- STORED PROCEDURES & PL/pgSQL AUTOMATION
-- PROCEDURE 3: Incremental Daily Sales Report Caching (BI Aggregation)
-- ============================================================================
-- BUSINESS PROBLEM STATEMENT:
-- Aggregating millions of order records on every dashboard load slows down 
-- corporate BI tools. We need a nightly procedure that computes and caches 
-- daily order counts, total revenues, and refunds into a materialized cache 
-- table to support sub-millisecond dashboard loads.
--
-- DESIGN RATIONALE:
-- Performs incremental loading for the past 7 days to absorb late-arriving shipping 
-- and payment updates, keeping the cache accurate without full-table re-scans.
-- ============================================================================

SET search_path TO core, public;

-- Create the target reporting cache table if it does not exist
CREATE TABLE IF NOT EXISTS core.daily_sales_cache (
    sales_date DATE PRIMARY KEY,
    total_orders INTEGER NOT NULL,
    gross_revenue NUMERIC(12, 2) NOT NULL,
    tax_collected NUMERIC(12, 2) NOT NULL,
    refunded_cash NUMERIC(12, 2) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE core.daily_sales_cache IS 'Materialized cache for daily operational metrics, updated nightly via stored procedures.';

-- Stored Procedure to incrementally load the cache
CREATE OR REPLACE PROCEDURE core.refresh_daily_sales_cache(
    p_lookback_days INTEGER DEFAULT 7
)
LANGUAGE plpgsql AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE := CURRENT_DATE;
BEGIN
    -- Determine the start of the refresh window
    v_start_date := (SELECT MAX(ordered_at)::DATE FROM core.orders) - p_lookback_days;
    
    RAISE NOTICE 'Refreshing daily sales cache from % to %...', v_start_date, v_end_date;
    
    -- Perform upsert (INSERT ... ON CONFLICT DO UPDATE) to merge fresh metrics
    INSERT INTO core.daily_sales_cache (sales_date, total_orders, gross_revenue, tax_collected, refunded_cash, updated_at)
    SELECT 
        o.ordered_at::DATE AS s_date,
        COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(o.total_amount) AS revenue_amount,
        SUM(o.tax_amount) AS tax_amount,
        COALESCE(SUM(ret.refunded_amount), 0.00) AS refunded_amount,
        CURRENT_TIMESTAMP
    FROM core.orders o
    LEFT JOIN core.order_items oi ON o.order_id = oi.order_id
    LEFT JOIN core.returns ret ON oi.order_item_id = ret.order_item_id
    WHERE o.ordered_at::DATE BETWEEN v_start_date AND v_end_date
      AND o.status NOT IN ('cancelled', 'payment_failed')
    GROUP BY o.ordered_at::DATE
    ON CONFLICT (sales_date) 
    DO UPDATE SET 
        total_orders = EXCLUDED.total_orders,
        gross_revenue = EXCLUDED.gross_revenue,
        tax_collected = EXCLUDED.tax_collected,
        refunded_cash = EXCLUDED.refunded_cash,
        updated_at = EXCLUDED.updated_at;
        
    RAISE NOTICE 'Daily sales cache refresh completed.';
END;
$$;
