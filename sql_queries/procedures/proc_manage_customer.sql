-- ============================================================================
-- STORED PROCEDURES & PL/pgSQL AUTOMATION
-- PROCEDURE 2: Customer Account Deactivation & Reservation Release
-- ============================================================================
-- BUSINESS CONTEXT:
-- When a customer closes their account or gets suspended due to fraud, security 
-- ops must deactivate the account and cancel all open pending orders, releasing 
-- reserved stock back to the warehouse inventory.
--
-- DESIGN RATIONALE:
-- Integrates account flagging with transactional inventory reversion to prevent 
-- stranded stock reservations.
-- ============================================================================

SET search_path TO core, public;

CREATE OR REPLACE PROCEDURE core.deactivate_customer_account(
    p_customer_id BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    r_order RECORD;
    r_item RECORD;
BEGIN
    -- 1. Deactivate the customer profile
    UPDATE core.customers
    SET is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', p_customer_id;
    END IF;
    
    -- 2. Locate and loop through all pending orders for this customer
    FOR r_order IN 
        SELECT order_id 
        FROM core.orders 
        WHERE customer_id = p_customer_id 
          AND status = 'pending'
    LOOP
        -- Release inventory reservations for this order
        FOR r_item IN 
            SELECT product_id, quantity 
            FROM core.order_items 
            WHERE order_id = r_order.order_id
        LOOP
            UPDATE core.inventory
            SET quantity_reserved = GREATEST(0, quantity_reserved - r_item.quantity),
                updated_at = CURRENT_TIMESTAMP
            WHERE product_id = r_item.product_id 
              AND warehouse_code = 'US-EAST-01';
        END LOOP;
        
        -- Transition order status to cancelled
        UPDATE core.orders
        SET status = 'cancelled',
            updated_at = CURRENT_TIMESTAMP
        WHERE order_id = r_order.order_id;
        
        RAISE NOTICE 'Pending Order ID % has been cancelled and stock reservations released.', r_order.order_id;
    END LOOP;
    
    RAISE NOTICE 'Customer ID % has been successfully deactivated.', p_customer_id;
END;
$$;
