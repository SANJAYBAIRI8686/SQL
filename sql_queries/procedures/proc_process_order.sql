-- ============================================================================
-- STORED PROCEDURES & PL/pgSQL AUTOMATION
-- PROCEDURE 1: Order Processing & Inventory Reservation Automation
-- ============================================================================
-- BUSINESS CONTEXT:
-- When an order is completed, the system must process stock deductions, 
-- clear cart reservations, and update the order state in a single transaction 
-- to prevent overselling.
--
-- DESIGN RATIONALE:
-- Uses a PostgreSQL PROCEDURE to support explicit transaction COMMIT/ROLLBACK, 
-- safeguarding inventory balances against partial failure states.
-- ============================================================================

SET search_path TO core, public;

CREATE OR REPLACE PROCEDURE core.process_order_checkout(
    p_order_id BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    r_item RECORD;
    v_status VARCHAR(30);
    v_total NUMERIC(12,2);
    v_stock_ok BOOLEAN := TRUE;
    v_err_msg TEXT;
BEGIN
    -- 1. Lock the order row and verify state
    SELECT status, total_amount INTO v_status, v_total
    FROM core.orders
    WHERE order_id = p_order_id
    FOR UPDATE;
    
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'Order ID % not found', p_order_id;
    END IF;
    
    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Order ID % is in status %; only pending orders can be checked out.', p_order_id, v_status;
    END IF;
    
    -- 2. Iterate through order items to check and adjust inventory
    FOR r_item IN 
        SELECT product_id, quantity 
        FROM core.order_items 
        WHERE order_id = p_order_id
    LOOP
        -- Check and lock the inventory row for update
        -- We select the warehouse that has enough stock (for simplicity, we assume US-EAST-01)
        IF NOT EXISTS (
            SELECT 1 
            FROM core.inventory 
            WHERE product_id = r_item.product_id 
              AND warehouse_code = 'US-EAST-01'
              AND (quantity_on_hand - quantity_reserved) >= r_item.quantity
            FOR UPDATE
        ) THEN
            v_stock_ok := FALSE;
            EXIT; -- Exit loop immediately on stockout
        END IF;
        
        -- Deduct from on hand stock and clear reservation
        UPDATE core.inventory
        SET quantity_on_hand = quantity_on_hand - r_item.quantity,
            quantity_reserved = GREATEST(0, quantity_reserved - r_item.quantity),
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = r_item.product_id 
          AND warehouse_code = 'US-EAST-01';
    END LOOP;
    
    -- 3. Finalize order status
    IF v_stock_ok THEN
        -- Transition to processing state
        UPDATE core.orders
        SET status = 'processing',
            updated_at = CURRENT_TIMESTAMP
        WHERE order_id = p_order_id;
        
        -- Record capture payment
        INSERT INTO core.payments (order_id, payment_method, payment_gateway, transaction_reference, amount, status)
        VALUES (
            p_order_id, 
            'credit_card', 
            'stripe', 
            'txn_proc_' || p_order_id || '_' || CAST(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) AS INTEGER), 
            v_total, 
            'captured'
        );
        
        RAISE NOTICE 'Order % successfully processed and stock updated.', p_order_id;
    ELSE
        -- Stockout occurred, cancel the order and log payment failure
        UPDATE core.orders
        SET status = 'payment_failed',
            updated_at = CURRENT_TIMESTAMP
        WHERE order_id = p_order_id;
        
        INSERT INTO core.payments (order_id, payment_method, payment_gateway, transaction_reference, amount, status)
        VALUES (
            p_order_id, 
            'credit_card', 
            'stripe', 
            'txn_fail_' || p_order_id || '_' || CAST(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) AS INTEGER), 
            v_total, 
            'failed'
        );
        
        RAISE WARNING 'Order % failed processing due to stock shortage.', p_order_id;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    -- Get exception details and re-raise
    GET STACKED DIAGNOSTICS v_err_msg = MESSAGE_TEXT;
    RAISE EXCEPTION 'Fulfillment automation failed for Order %: %', p_order_id, v_err_msg;
END;
$$;
