-- ============================================================================
-- SQL PORTFOLIO PROJECT: SEED SAMPLE SQL (INSERT STATEMENTS)
-- Target Database: PostgreSQL 13+
-- Author: Senior Database Architect
-- Purpose: Provides a small, fully executable sample dataset containing INSERT 
--          statements for immediate verification, onboarding, and testing.
-- ============================================================================

BEGIN;

-- Clear any existing sample data in the core schema
TRUNCATE core.returns, core.reviews, core.shipments, core.payments, 
         core.order_items, core.orders, core.inventory, core.products, 
         core.addresses, core.customers, core.categories RESTART IDENTITY CASCADE;

-- 1. Seed Categories
INSERT INTO core.categories (category_id, name, slug, description, parent_category_id) VALUES
(1, 'Electronics', 'electronics', 'Consumer gadgets and hardware.', NULL),
(2, 'Computers', 'computers', 'Laptops and tablets.', 1),
(4, 'Apparel', 'apparel', 'Clothing and garments.', NULL),
(5, 'Men''s Clothing', 'mens-clothing', 'Shirts, jeans, and coats.', 4);

-- 2. Seed Customers
INSERT INTO core.customers (customer_id, email, first_name, last_name, phone, is_active) VALUES
(1, 'alex.jones@example.com', 'Alex', 'Jones', '+1-555-019-2834', TRUE),
(2, 'maria.gomez@example.com', 'Maria', 'Gomez', '+1-555-019-5832', TRUE),
(3, 'sam.wilson@example.com', 'Sam', 'Wilson', '+1-555-019-1122', TRUE);

-- 3. Seed Addresses
INSERT INTO core.addresses (address_id, customer_id, address_type, recipient_name, address_line1, address_line2, city, state_province, postal_code, country, is_default) VALUES
(1, 1, 'both', 'Alex Jones', '123 Pine St', 'Apt 2B', 'Seattle', 'WA', '98101', 'United States', TRUE),
(2, 2, 'shipping', 'Maria Gomez', '456 Oak Ave', NULL, 'Austin', 'TX', '78701', 'United States', TRUE),
(3, 2, 'billing', 'Maria Gomez', '789 Maple Rd', NULL, 'Austin', 'TX', '78702', 'United States', FALSE),
(4, 3, 'both', 'Sam Wilson', '101 Broadway', NULL, 'New York City', 'NY', '10001', 'United States', TRUE);

-- 4. Seed Products
INSERT INTO core.products (product_id, category_id, sku, name, slug, description, price, cost, status) VALUES
(1, 2, 'LAP-APEX-01', 'Apex Premium Laptop', 'apex-premium-laptop', 'Flagship ultraportable laptop.', 1299.99, 800.00, 'active'),
(2, 2, 'TAB-NEXUS-02', 'Nexus Smart Tablet', 'nexus-smart-tablet', 'Lightweight 10-inch smart tablet.', 349.99, 210.00, 'active'),
(3, 5, 'APP-TSHIRT-03', 'Vortex Classic T-Shirt', 'vortex-classic-t-shirt', '100% organic cotton crewneck.', 24.99, 10.00, 'active');

-- 5. Seed Inventory
INSERT INTO core.inventory (inventory_id, product_id, warehouse_code, quantity_on_hand, quantity_reserved, low_stock_threshold) VALUES
(1, 1, 'US-WEST-01', 50, 5, 10),
(2, 1, 'US-EAST-01', 40, 2, 10),
(3, 2, 'US-WEST-01', 120, 15, 20),
(4, 3, 'US-EAST-01', 300, 20, 50);

-- 6. Seed Orders
INSERT INTO core.orders (order_id, customer_id, shipping_address_id, billing_address_id, status, total_amount, tax_amount, shipping_amount, ordered_at) VALUES
(1, 1, 1, 1, 'delivered', 1334.98, 100.00, 0.00, '2026-06-15 14:30:00+00'),
(2, 2, 2, 3, 'processing', 374.98, 25.00, 0.00, '2026-06-25 10:15:00+00'),
(3, 3, 4, 4, 'cancelled', 34.98, 2.00, 7.99, '2026-06-20 09:00:00+00');

-- 7. Seed Order Items
INSERT INTO core.order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_amount) VALUES
(1, 1, 1, 1, 1299.99, 65.00), -- Net: 1234.99
(2, 2, 2, 1, 349.99, 0.00),    -- Net: 349.99
(3, 3, 3, 1, 24.99, 0.00);      -- Net: 24.99

-- 8. Seed Payments
INSERT INTO core.payments (payment_id, order_id, payment_method, payment_gateway, transaction_reference, amount, status) VALUES
(1, 1, 'credit_card', 'stripe', 'txn_000001', 1334.98, 'captured'),
(2, 2, 'paypal', 'paypal', 'txn_000002', 374.98, 'captured'),
(3, 3, 'apple_pay', 'stripe', 'txn_000003', 34.98, 'voided');

-- 9. Seed Shipments
INSERT INTO core.shipments (shipment_id, order_id, carrier, tracking_number, status, estimated_delivery, shipped_at, delivered_at) VALUES
(1, 1, 'FedEx', 'TRACK000001', 'delivered', '2026-06-20 17:00:00+00', '2026-06-16 09:00:00+00', '2026-06-19 15:22:00+00'),
(2, 2, 'UPS', 'TRACK000002', 'label_created', '2026-06-30 17:00:00+00', NULL, NULL);

-- 10. Seed Reviews
INSERT INTO core.reviews (review_id, product_id, customer_id, rating, title, comment) VALUES
(1, 1, 1, 5, 'Superb device!', 'Extremely fast and lightweight laptop.'),
(2, 2, 2, 4, 'Very handy', 'Great screen, but battery could be slightly better.');

-- 11. Seed Returns
INSERT INTO core.returns (return_id, order_item_id, reason, status, refunded_amount) VALUES
-- No returns yet processed (Maria Gomez's order is still processing, Alex's is kept, Sam's is cancelled).
-- This demonstrates return statistics empty state handling.
;

-- Re-syncing sequence generators
SELECT setval(pg_get_serial_sequence('core.categories', 'category_id'), COALESCE(MAX(category_id), 1)) FROM core.categories;
SELECT setval(pg_get_serial_sequence('core.customers', 'customer_id'), COALESCE(MAX(customer_id), 1)) FROM core.customers;
SELECT setval(pg_get_serial_sequence('core.addresses', 'address_id'), COALESCE(MAX(address_id), 1)) FROM core.addresses;
SELECT setval(pg_get_serial_sequence('core.products', 'product_id'), COALESCE(MAX(product_id), 1)) FROM core.products;
SELECT setval(pg_get_serial_sequence('core.inventory', 'inventory_id'), COALESCE(MAX(inventory_id), 1)) FROM core.inventory;
SELECT setval(pg_get_serial_sequence('core.orders', 'order_id'), COALESCE(MAX(order_id), 1)) FROM core.orders;
SELECT setval(pg_get_serial_sequence('core.order_items', 'order_item_id'), COALESCE(MAX(order_item_id), 1)) FROM core.order_items;
SELECT setval(pg_get_serial_sequence('core.payments', 'payment_id'), COALESCE(MAX(payment_id), 1)) FROM core.payments;
SELECT setval(pg_get_serial_sequence('core.shipments', 'shipment_id'), COALESCE(MAX(shipment_id), 1)) FROM core.shipments;
SELECT setval(pg_get_serial_sequence('core.reviews', 'review_id'), COALESCE(MAX(review_id), 1)) FROM core.reviews;
SELECT setval(pg_get_serial_sequence('core.returns', 'return_id'), COALESCE(MAX(return_id), 1)) FROM core.returns;

COMMIT;
