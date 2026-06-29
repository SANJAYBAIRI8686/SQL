-- ============================================================================
-- SQL PORTFOLIO PROJECT: OMNISHOP E-COMMERCE CORE SCHEMA
-- Target Database: PostgreSQL 13+ (compatible with Google Cloud SQL)
-- Relational Model: Third Normal Form (3NF)
-- Architect: Senior Database Architect
-- ============================================================================
-- Design Rationale:
-- 1. All primary keys utilize GENERATED ALWAYS AS IDENTITY. This is the modern
--    SQL-standard compliant replacement for SERIAL, preventing manual injection 
--    and keeping the sequence in sync.
-- 2. Timezones: TIMESTAMPTZ is strictly enforced to avoid data ambiguity 
--    across multi-region cloud servers (e.g. Google Cloud SQL multi-zone).
-- 3. Money Storage: NUMERIC(12, 2) is used for exact decimal arithmetic, 
--    avoiding float/double rounding errors that could cause ledger discrepancies.
-- 4. Normalization: A separate `addresses` table handles multiple shipping/billing 
--    locations per customer, adhering to 3NF and preventing duplication in `orders`
--    and `customers` tables.
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS core;
SET search_path TO core, public;

-- ----------------------------------------------------------------------------
-- 1. CATEGORIES TABLE
-- ----------------------------------------------------------------------------
-- Why: Self-referencing relationship allows infinite nesting of categories
-- (e.g., Electronics -> Computers -> Laptops), which is standard in catalogs.
CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL UNIQUE, -- SEO-friendly identifier for routing
    description TEXT,
    parent_category_id BIGINT REFERENCES categories(category_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categories IS 'Hierarchical catalog structure for grouping products.';
COMMENT ON COLUMN categories.parent_category_id IS 'Points to the parent category. SET NULL on parent deletion to preserve child categories.';
COMMENT ON COLUMN categories.slug IS 'Unique slug for URL routing, e.g. "smart-home-devices".';


-- ----------------------------------------------------------------------------
-- 2. CUSTOMERS TABLE
-- ----------------------------------------------------------------------------
-- Why: Focuses purely on customer credentials and identity. Address details
-- are moved to the `addresses` table to satisfy 3NF (preventing multi-value attributes).
CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE customers IS 'Customer accounts registry storing authentication, contact information, and state.';
COMMENT ON COLUMN customers.email IS 'Primary identifier for customer logins. Must be unique across the platform.';


-- ----------------------------------------------------------------------------
-- 3. ADDRESSES TABLE
-- ----------------------------------------------------------------------------
-- Why: Normalizes the relationship between customers and their address book.
-- Shipping and billing addresses can be reused or flagged as defaults.
CREATE TABLE addresses (
    address_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    address_type VARCHAR(20) NOT NULL CHECK (address_type IN ('shipping', 'billing', 'both')),
    recipient_name VARCHAR(200) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE addresses IS 'Customer shipping and billing address book.';
COMMENT ON COLUMN addresses.customer_id IS 'Cascades on customer deletion since addresses have no value without a parent customer.';


-- ----------------------------------------------------------------------------
-- 4. PRODUCTS TABLE
-- ----------------------------------------------------------------------------
-- Why: Stored cost and price separately to calculate profit margin. SKU is
-- unique to ensure operational mapping with physical supply chain systems.
CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id BIGINT NOT NULL REFERENCES categories(category_id) ON DELETE RESTRICT,
    sku VARCHAR(50) NOT NULL UNIQUE, -- Stock Keeping Unit (Unique Business Key)
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE, -- SEO routing URL
    description TEXT,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0.00),
    cost NUMERIC(12, 2) NOT NULL CHECK (cost >= 0.00),
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'out_of_stock', 'discontinued')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE products IS 'Master product catalog containing specifications, pricing, and lifecycle state.';
COMMENT ON COLUMN products.category_id IS 'RESTRICT prevent deletion of a category if products are assigned to it.';
COMMENT ON COLUMN products.sku IS 'Alphanumeric barcode string mapped to logistics software.';


-- ----------------------------------------------------------------------------
-- 5. INVENTORY TABLE
-- ----------------------------------------------------------------------------
-- Why: Supports multi-warehouse logistics. Includes reserved quantities to
-- prevent overselling before payment is finalized/shipment is dispatched.
CREATE TABLE inventory (
    inventory_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    warehouse_code VARCHAR(50) NOT NULL,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    low_stock_threshold INTEGER NOT NULL DEFAULT 10 CHECK (low_stock_threshold >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, warehouse_code),
    -- Business logic check: Reserved stock must not exceed total physical stock on hand.
    CONSTRAINT chk_reserved_vs_hand CHECK (quantity_reserved <= quantity_on_hand)
);

COMMENT ON TABLE inventory IS 'Warehouse stock tracking ledger. Multi-warehouse compatible.';
COMMENT ON COLUMN inventory.quantity_on_hand IS 'Total physical count of stock items present in the warehouse.';
COMMENT ON COLUMN inventory.quantity_reserved IS 'Stock allocated to open/unfilled customer orders. Safe from double selling.';


-- ----------------------------------------------------------------------------
-- 6. ORDERS TABLE
-- ----------------------------------------------------------------------------
-- Why: Tracks historical shipping and billing addresses to safeguard against
-- future customer address edits changing prior tax/shipping reports.
CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    shipping_address_id BIGINT NOT NULL REFERENCES addresses(address_id) ON DELETE RESTRICT,
    billing_address_id BIGINT NOT NULL REFERENCES addresses(address_id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'payment_failed', 'processing', 'partially_shipped', 'shipped', 'delivered', 'cancelled', 'returned')),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0.00),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0.00),
    shipping_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (shipping_amount >= 0.00),
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE orders IS 'E-commerce transactional headers. Tracks orders from creation to delivery/cancellation.';
COMMENT ON COLUMN orders.shipping_address_id IS 'Address where the items are shipped. RESTRICT prevents deleting used addresses.';


-- ----------------------------------------------------------------------------
-- 7. ORDER_ITEMS TABLE
-- ----------------------------------------------------------------------------
-- Why: Stores snapshot of price at order time. A generated column simplifies
-- calculations of net line item prices while preserving performance.
CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0.00),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0.00),
    -- Generated Column to automate query reporting without manual math logic in BI layers.
    net_price NUMERIC(12, 2) GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Prevent duplicate products in the same order. Increases quantity instead.
    UNIQUE (order_id, product_id)
);

COMMENT ON TABLE order_items IS 'Line-item details mapping orders to products, quantity, and historical pricing snapshots.';
COMMENT ON COLUMN order_items.unit_price IS 'Price of the product at the time the order was placed, insulating from future price updates.';


-- ----------------------------------------------------------------------------
-- 8. PAYMENTS TABLE
-- ----------------------------------------------------------------------------
-- Why: Maps payments to orders. Uses unique transaction references to prevent
-- duplicate charge processing from the application gateway side.
CREATE TABLE payments (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('credit_card', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer')),
    payment_gateway VARCHAR(50) NOT NULL, -- e.g., STRIPE, ADYEN, PAYPAL
    transaction_reference VARCHAR(100) NOT NULL UNIQUE, -- Gateway transaction code
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0.00),
    status VARCHAR(30) NOT NULL CHECK (status IN ('pending', 'authorized', 'captured', 'failed', 'refunded', 'voided')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE payments IS 'Payment transactions ledger validating money capture per order.';
COMMENT ON COLUMN payments.transaction_reference IS 'Unique hash/string provided by payment processor to prevent double capturing.';


-- ----------------------------------------------------------------------------
-- 9. SHIPMENTS TABLE
-- ----------------------------------------------------------------------------
-- Why: Logs shipping details separately from orders to allow multiple shipments
-- per order (e.g., partial shipments) and tracks tracking timelines.
CREATE TABLE shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    carrier VARCHAR(50) NOT NULL, -- FedEx, UPS, DHL, USPS
    tracking_number VARCHAR(100) UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'label_created' CHECK (status IN ('label_created', 'in_transit', 'out_for_delivery', 'delivered', 'failed_attempt', 'returned_to_sender')),
    estimated_delivery TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Integrity Check: Cannot deliver before shipping
    CONSTRAINT chk_delivery_dates CHECK (delivered_at IS NULL OR (shipped_at IS NOT NULL AND delivered_at >= shipped_at))
);

COMMENT ON TABLE shipments IS 'Logistics shipping registry containing carrier statuses and tracking details.';


-- ----------------------------------------------------------------------------
-- 10. REVIEWS TABLE
-- ----------------------------------------------------------------------------
-- Why: Stores product testimonials. Unique constraint ensures a customer
-- can review a product only once to preserve catalog integrity and trust.
CREATE TABLE reviews (
    review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(255),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, customer_id)
);

COMMENT ON TABLE reviews IS 'Product ratings and review details left by customers.';


-- ----------------------------------------------------------------------------
-- 11. RETURNS TABLE
-- ----------------------------------------------------------------------------
-- Why: Models the lifecycle of post-purchase logistics. References the specific
-- order line item to ensure accuracy of inventory restocks and refunds.
CREATE TABLE returns (
    return_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_item_id BIGINT NOT NULL UNIQUE REFERENCES order_items(order_item_id) ON DELETE RESTRICT,
    reason VARCHAR(50) NOT NULL CHECK (reason IN ('damaged', 'defective', 'wrong_item', 'size_fit', 'buyer_remorse', 'late_delivery', 'other')),
    status VARCHAR(30) NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'approved', 'item_received', 'refunded', 'rejected')),
    refunded_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (refunded_amount >= 0.00),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE returns IS 'Return management ledger tracking return shipping status and financial refunds.';
COMMENT ON COLUMN returns.order_item_id IS 'Unique link back to order_item. Limits returns to one record per unique line-item.';

-- ----------------------------------------------------------------------------
-- INDEXING STRATEGY (PERFORMANCE TUNING)
-- ----------------------------------------------------------------------------
-- B-Tree Indexes on Foreign Keys (Crucial for JOIN performance and cascading DELETE locks)
CREATE INDEX idx_categories_parent_id ON categories(parent_category_id);
CREATE INDEX idx_addresses_customer_id ON addresses(customer_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_shipping_address_id ON orders(shipping_address_id);
CREATE INDEX idx_orders_billing_address_id ON orders(billing_address_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_shipments_order_id ON shipments(order_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_customer_id ON reviews(customer_id);

-- Functional Index for Case-Insensitive User Logins
CREATE INDEX idx_customers_lower_email ON customers (LOWER(email));

-- Composite Index for Customer Order Dashboards (Sorted descending for instant retrieval)
CREATE INDEX idx_orders_customer_date_desc ON orders (customer_id, ordered_at DESC);

-- Partial Index for Active Storefront Catalog Items
CREATE INDEX idx_products_active ON products (product_id) WHERE status = 'active';

-- Partial Indexes for Operational Queues (Fulfillment & Warehousing)
CREATE INDEX idx_orders_unfulfilled ON orders (order_id) WHERE status IN ('pending', 'processing');
CREATE INDEX idx_shipments_pending ON shipments (shipment_id) WHERE status NOT IN ('delivered', 'returned_to_sender');

COMMIT;

