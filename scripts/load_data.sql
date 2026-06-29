-- ============================================================================
-- DATA INGESTION SCRIPT FOR OMNISHOP DATABASE
-- Target: PostgreSQL (compatible with local psql CLI and Google Cloud SQL)
-- Author: Senior Database Architect
-- Purpose: Ingests synthetic CSV files into 3NF schema tables using the client-side
--          \copy command and synchronizes identity sequences afterwards.
-- Run command: psql -h <host> -U <user> -d <db> -f scripts/load_data.sql
-- ============================================================================

-- Disable triggers temporarily if running with superuser to speed up copy.
-- (Note: If running as standard DB user on Cloud SQL, triggers remain active for safety).
-- ALTER TABLE core.order_items DISABLE TRIGGER ALL;

BEGIN;

-- 1. Categories
\copy core.categories(category_id, name, slug, description, parent_category_id) FROM 'datasets/categories.csv' WITH CSV HEADER;

-- 2. Customers
\copy core.customers(customer_id, email, first_name, last_name, phone, is_active, created_at, updated_at) FROM 'datasets/customers.csv' WITH CSV HEADER;

-- 3. Addresses
\copy core.addresses(address_id, customer_id, address_type, recipient_name, address_line1, address_line2, city, state_province, postal_code, country, is_default, created_at, updated_at) FROM 'datasets/addresses.csv' WITH CSV HEADER;

-- 4. Products
\copy core.products(product_id, category_id, sku, name, slug, description, price, cost, status, created_at, updated_at) FROM 'datasets/products.csv' WITH CSV HEADER;

-- 5. Inventory
\copy core.inventory(inventory_id, product_id, warehouse_code, quantity_on_hand, quantity_reserved, low_stock_threshold, updated_at) FROM 'datasets/inventory.csv' WITH CSV HEADER;

-- 6. Orders
\copy core.orders(order_id, customer_id, shipping_address_id, billing_address_id, status, total_amount, tax_amount, shipping_amount, ordered_at, updated_at) FROM 'datasets/orders.csv' WITH CSV HEADER;

-- 7. Order Items
\copy core.order_items(order_item_id, order_id, product_id, quantity, unit_price, discount_amount) FROM 'datasets/order_items.csv' WITH CSV HEADER;

-- 8. Payments
\copy core.payments(payment_id, order_id, payment_method, payment_gateway, transaction_reference, amount, status, created_at, updated_at) FROM 'datasets/payments.csv' WITH CSV HEADER;

-- 9. Shipments
\copy core.shipments(shipment_id, order_id, carrier, tracking_number, status, estimated_delivery, shipped_at, delivered_at, created_at, updated_at) FROM 'datasets/shipments.csv' WITH CSV HEADER;

-- 10. Reviews
\copy core.reviews(review_id, product_id, customer_id, rating, title, comment, created_at, updated_at) FROM 'datasets/reviews.csv' WITH CSV HEADER;

-- 11. Returns
\copy core.returns(return_id, order_item_id, reason, status, refunded_amount, created_at, updated_at) FROM 'datasets/returns.csv' WITH CSV HEADER;

COMMIT;

-- ============================================================================
-- IDENTITY SEQUENCE SYNCHRONIZATION
-- ============================================================================
-- When copying values directly into columns using GENERATED ALWAYS AS IDENTITY,
-- PostgreSQL's internal sequence counters are not advanced. We must sync them
-- with the MAX(id) of each table to prevent future INSERT collisions.
-- ============================================================================

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
