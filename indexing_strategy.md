# Indexing Strategy & Performance Tuning Report

This document details the indexing design system implemented for the **OmniShop** database. As a production-grade database handling high-concurrency e-commerce operations, proper indexing is critical to avoid full-table scans, accelerate common `JOIN` paths, and prevent locking issues during cascade deletions.

---

## 1. Automated Indexes (PostgreSQL Defaults)
PostgreSQL automatically creates B-tree indexes for columns declared with `PRIMARY KEY` or `UNIQUE` constraints. We do not need to create these manually, but our query optimization strategy counts on them:

*   **Primary Keys:**
    *   `categories(category_id)`
    *   `customers(customer_id)`
    *   `addresses(address_id)`
    *   `products(product_id)`
    *   `inventory(inventory_id)`
    *   `orders(order_id)`
    *   `order_items(order_item_id)`
    *   `payments(payment_id)`
    *   `shipments(shipment_id)`
    *   `reviews(review_id)`
    *   `returns(return_id)`
*   **Unique Constraints (Implicit Indexes):**
    *   `categories(slug)`
    *   `customers(email)`
    *   `products(sku)`
    *   `products(slug)`
    *   `inventory(product_id, warehouse_code)` (Composite Unique)
    *   `order_items(order_id, product_id)` (Composite Unique)
    *   `payments(transaction_reference)`
    *   `shipments(tracking_number)`
    *   `reviews(product_id, customer_id)` (Composite Unique)
    *   `returns(order_item_id)`

---

## 2. Foreign Key Indexes (Manual B-Tree)
**Problem:** PostgreSQL does *not* automatically create indexes on foreign keys. When joining tables (e.g. `orders` to `customers`), or when deleting records in a parent table (which triggers a scan of the child table to satisfy referential integrity checks), the database must perform a full-table scan on the child table if no index exists.
**Solution:** We implement B-tree indexes on all foreign key columns.

```sql
-- Categories hierarchical self-reference
CREATE INDEX idx_categories_parent_id ON core.categories(parent_category_id);

-- Customer Addresses
CREATE INDEX idx_addresses_customer_id ON core.addresses(customer_id);

-- Product Catalog
CREATE INDEX idx_products_category_id ON core.products(category_id);

-- Warehouse Inventory
CREATE INDEX idx_inventory_product_id ON core.inventory(product_id);

-- Transaction Headers
CREATE INDEX idx_orders_customer_id ON core.orders(customer_id);
CREATE INDEX idx_orders_shipping_address_id ON core.orders(shipping_address_id);
CREATE INDEX idx_orders_billing_address_id ON core.orders(billing_address_id);

-- Order Items
CREATE INDEX idx_order_items_order_id ON core.order_items(order_id);
CREATE INDEX idx_order_items_product_id ON core.order_items(product_id);

-- Payments
CREATE INDEX idx_payments_order_id ON core.payments(order_id);

-- Shipments
CREATE INDEX idx_shipments_order_id ON core.shipments(order_id);

-- Reviews
CREATE INDEX idx_reviews_product_id ON core.reviews(product_id);
CREATE INDEX idx_reviews_customer_id ON core.reviews(customer_id);
```

---

## 3. High-Performance Query Specific Indexes

### 3.1 Case-Insensitive Email Lookup (Functional Index)
When customers log in, application frameworks typically query `SELECT * FROM customers WHERE LOWER(email) = LOWER(?);` to ensure logins are case-insensitive. A standard index on `email` is not utilized by the query planner when the column is wrapped in a function.
We implement an expression index:

```sql
CREATE INDEX idx_customers_lower_email ON core.customers (LOWER(email));
```

### 3.2 Customer Order History (Composite Index with Sort Order)
A common dashboard query is displaying a customer's order history, sorted by order date descending. A single-column index on `customer_id` is sufficient for filtering, but forces the database to sort the matching rows in memory.
We create a composite index sorting the timestamps in descending order to allow direct index scans:

```sql
CREATE INDEX idx_orders_customer_date_desc ON core.orders (customer_id, ordered_at DESC);
```

### 3.3 Active Product Filter (Partial / Filtered Index)
The storefront catalog frequently queries active products (`WHERE status = 'active'`). Discontinued or draft products represent historical data that shouldn't slow down the storefront.
We create a partial index to keep the index footprint minimal:

```sql
CREATE INDEX idx_products_active ON core.products (product_id) 
WHERE status = 'active';
```

### 3.4 Unfulfilled Order Queue (Partial Index)
The warehouse fulfillment system continuously polls for uncompleted shipments or orders to process (`WHERE status IN ('pending', 'processing')`).
Rather than indexing millions of archived historical orders, we index the active working queue:

```sql
CREATE INDEX idx_orders_unfulfilled ON core.orders (order_id) 
WHERE status IN ('pending', 'processing');

CREATE INDEX idx_shipments_pending ON core.shipments (shipment_id) 
WHERE status NOT IN ('delivered', 'returned_to_sender');
```

---

## 4. Summary of Index Cost vs. Benefit
| Index Name | Table | Columns | Type / Filter | Business Scenario |
| :--- | :--- | :--- | :--- | :--- |
| `idx_customers_lower_email` | `customers` | `LOWER(email)` | Expression / B-Tree | Fast user logins without full scans. |
| `idx_orders_customer_date_desc` | `orders` | `customer_id, ordered_at DESC` | Composite B-Tree | Instantly rendering user dashboard "Recent Orders". |
| `idx_products_active` | `products` | `product_id` | Partial / Filtered | Fast storefront browsing of active products. |
| `idx_orders_unfulfilled` | `orders` | `order_id` | Partial / Filtered | Fast polling of pending orders for fulfillment workers. |
| `idx_*_id` (FKs) | Various | FK ID | B-Tree | Drastically speeds up multi-table `JOIN` statements. |
