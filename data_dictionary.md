# Data Dictionary

This document details every table, column, data type, integrity constraint, and business meaning within the **OmniShop** database schema.

---

## 1. Table: `categories`
Hierarchical catalog structure for grouping products.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `category_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for categories | `105` |
| `name` | `VARCHAR(100)`| - | NO | - | Display name of the category | `"Laptops & Netbooks"` |
| `slug` | `VARCHAR(120)`| UK | NO | - | URL routing slug (lowercase, hyphenated) | `"laptops-netbooks"` |
| `description` | `TEXT` | - | YES | `NULL` | Detailed description of category contents | `"Portable computer systems..."` |
| `parent_category_id` | `BIGINT` | FK | YES | `NULL` | Self-reference to parent category for nesting | `12` (e.g. Computers) |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: record creation date | `2026-06-28 14:00:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: last modification date | `2026-06-28 14:00:00Z` |

---

## 2. Table: `customers`
Primary customer accounts registry containing contact profiles.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `customer_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for customers | `98432` |
| `email` | `VARCHAR(255)`| UK | NO | - | Primary account email (lowercase login key) | `"alice.smith@gmail.com"` |
| `first_name` | `VARCHAR(100)`| - | NO | - | Customer's first name | `"Alice"` |
| `last_name` | `VARCHAR(100)`| - | NO | - | Customer's last name | `"Smith"` |
| `phone` | `VARCHAR(30)` | - | YES | `NULL` | Customer phone number with country codes | `"+1-555-019-2834"` |
| `is_active` | `BOOLEAN` | - | NO | `TRUE` | Soft-deletion or suspension flag | `true` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: registration date | `2026-05-15 08:32:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: profile last update | `2026-06-20 10:15:00Z` |

---

## 3. Table: `addresses`
Customer address book supporting multiple shipping/billing destinations.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `address_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for addresses | `5431` |
| `customer_id` | `BIGINT` | FK | NO | - | References `customers.customer_id` | `98432` |
| `address_type` | `VARCHAR(20)`| - | NO | - | Type check: `'shipping'`, `'billing'`, `'both'` | `"shipping"` |
| `recipient_name` | `VARCHAR(200)`| - | NO | - | Full name of shipping recipient | `"Alice Smith"` |
| `address_line1` | `VARCHAR(255)`| - | NO | - | Primary street address, suite, PO box | `"123 Maple St"` |
| `address_line2` | `VARCHAR(255)`| - | YES | `NULL` | Secondary address line (apartment, floor) | `"Apt 4B"` |
| `city` | `VARCHAR(100)`| - | NO | - | City name | `"Seattle"` |
| `state_province` | `VARCHAR(100)`| - | NO | - | State, province, or region | `"WA"` |
| `postal_code` | `VARCHAR(20)` | - | NO | - | ZIP or postal code | `"98101"` |
| `country` | `VARCHAR(100)`| - | NO | - | Country name | `"United States"` |
| `is_default` | `BOOLEAN` | - | NO | `FALSE` | Flag designating the customer's primary address | `true` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: creation date | `2026-05-15 08:35:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: last update date | `2026-05-15 08:35:00Z` |

---

## 4. Table: `products`
Master catalog items details containing identifiers, dimensions, cost, and price.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `product_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for products | `872` |
| `category_id` | `BIGINT` | FK | NO | - | References `categories.category_id` | `105` |
| `sku` | `VARCHAR(50)`| UK | NO | - | Unique Stock Keeping Unit (barcode number) | `"LAP-DELL-XPS13-09"` |
| `name` | `VARCHAR(255)`| - | NO | - | Marketing name of the product | `"Dell XPS 13 Laptop"` |
| `slug` | `VARCHAR(255)`| UK | NO | - | SEO routing URL slug | `"dell-xps-13-laptop"` |
| `description` | `TEXT` | - | YES | `NULL` | Rich product specification description | `"Intel i7, 16GB RAM..."` |
| `price` | `NUMERIC(12,2)`| - | NO | - | Storefront selling price (must be >= 0.00) | `1299.99` |
| `cost` | `NUMERIC(12,2)`| - | NO | - | internal supply cost to calculate profit | `850.00` |
| `status` | `VARCHAR(20)`| - | NO | `'draft'` | Storefront lifecycle: draft, active, out_of_stock | `"active"` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: record birth date | `2026-06-01 12:00:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: last specs update | `2026-06-25 15:30:00Z` |

---

## 5. Table: `inventory`
Physical quantity ledger across multiple distinct warehouses.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `inventory_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for inventory | `43210` |
| `product_id` | `BIGINT` | FK | NO | - | References `products.product_id` | `872` |
| `warehouse_code`| `VARCHAR(50)`| UK (comp) | NO | - | Physical code for the holding warehouse | `"US-WEST-SEA"` |
| `quantity_on_hand`| `INTEGER`| - | NO | `0` | Total physical stock (incl. reserved) | `150` |
| `quantity_reserved`|`INTEGER`| - | NO | `0` | Stock allocated to checkouts (not yet shipped) | `15` |
| `low_stock_threshold`|`INTEGER`| - | NO | `10` | Alert trigger level for re-ordering | `20` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: last inventory count adjustment | `2026-06-28 19:40:00Z` |

---

## 6. Table: `orders`
E-commerce transactional headers aggregating purchase order metrics.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `order_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for orders | `654321` |
| `customer_id` | `BIGINT` | FK | NO | - | References `customers.customer_id` | `98432` |
| `shipping_address_id`|`BIGINT`| FK | NO | - | References `addresses.address_id` (snapshot) | `5431` |
| `billing_address_id`|`BIGINT` | FK | NO | - | References `addresses.address_id` (snapshot) | `5431` |
| `status` | `VARCHAR(30)`| - | NO | `'pending'` | order status: pending, processing, shipped, etc | `"processing"` |
| `total_amount` | `NUMERIC(12,2)`| - | NO | - | Total final cost paid by client | `1324.99` |
| `tax_amount` | `NUMERIC(12,2)`| - | NO | `0.00` | Calculated tax surcharge | `100.00` |
| `shipping_amount`| `NUMERIC(12,2)`| - | NO | `0.00` | Calculated shipping fee | `15.00` |
| `ordered_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Timestamp when order was submitted | `2026-06-28 18:22:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: last status change | `2026-06-28 18:25:00Z` |

---

## 7. Table: `order_items`
Detailed line-items mapping specific quantities and pricing snapshots per purchase.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `order_item_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for order item lines | `1087654` |
| `order_id` | `BIGINT` | FK | NO | - | References `orders.order_id` | `654321` |
| `product_id` | `BIGINT` | FK | NO | - | References `products.product_id` | `872` |
| `quantity` | `INTEGER` | - | NO | - | Number of units purchased (must be > 0) | `1` |
| `unit_price` | `NUMERIC(12,2)`| - | NO | - | Product price snapshot at order submission | `1299.99` |
| `discount_amount`| `NUMERIC(12,2)`| - | NO | `0.00` | Promotional deduction applied to item | `90.00` |
| `net_price` | `NUMERIC(12,2)`| - | NO | `GENERATED` | Generated total: `(qty * unit_price) - discount`| `1209.99` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: record generation | `2026-06-28 18:22:00Z` |

---

## 8. Table: `payments`
Ledger capturing transaction authorization and completion logs.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `payment_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for payments | `22334` |
| `order_id` | `BIGINT` | FK | NO | - | References `orders.order_id` | `654321` |
| `payment_method`| `VARCHAR(50)`| - | NO | - | Method: credit_card, paypal, apple_pay, bank... | `"credit_card"` |
| `payment_gateway`| `VARCHAR(50)`| - | NO | - | Payment gateway provider | `"stripe"` |
| `transaction_reference`|`VARCHAR(100)`| UK | NO | - | Gateway provider's unique charge identifier | `"ch_3M4tWd2eZvKYlo2C0oW9bQ"`|
| `amount` | `NUMERIC(12,2)`| - | NO | - | Total cash value authorized/captured | `1324.99` |
| `status` | `VARCHAR(30)`| - | NO | - | Gateway state: pending, authorized, captured | `"captured"` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: payment attempt | `2026-06-28 18:23:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: state update | `2026-06-28 18:24:00Z` |

---

## 9. Table: `shipments`
Logistics tracker representing cargo handoff, dispatch, and delivery.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `shipment_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for shipment | `998877` |
| `order_id` | `BIGINT` | FK | NO | - | References `orders.order_id` | `654321` |
| `carrier` | `VARCHAR(50)`| - | NO | - | Logistics firm: FedEx, UPS, DHL, USPS | `"FedEx"` |
| `tracking_number`|`VARCHAR(100)`| UK | YES | `NULL` | Carrier tracking barcode | `"1Z999AA10123456784"` |
| `status` | `VARCHAR(30)`| - | NO | `'label_created'` | shipment state: label_created, in_transit...| `"in_transit"` |
| `estimated_delivery`|`TIMESTAMPTZ`| - | YES | `NULL` | Estimated delivery window | `2026-07-02 17:00:00Z` |
| `shipped_at` | `TIMESTAMPTZ`| - | YES | `NULL` | Actual carrier pickup timestamp | `2026-06-29 10:00:00Z` |
| `delivered_at` | `TIMESTAMPTZ`| - | YES | `NULL` | Final package dropoff signature timestamp | `NULL` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: logistics initialization | `2026-06-28 19:00:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: status update | `2026-06-29 10:00:00Z` |

---

## 10. Table: `reviews`
Storefront product feedback ratings and customer opinions.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `review_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for reviews | `334455` |
| `product_id` | `BIGINT` | FK | NO | - | References `products.product_id` | `872` |
| `customer_id` | `BIGINT` | FK | NO | - | References `customers.customer_id` | `98432` |
| `rating` | `INTEGER` | - | NO | - | Score constraint: `BETWEEN 1 AND 5` | `5` |
| `title` | `VARCHAR(255)`| - | YES | `NULL` | Summary title of review | `"Incredible battery life!"` |
| `comment` | `TEXT` | - | YES | `NULL` | Full-text content body | `"The screen is extremely bright..."` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: review date | `2026-07-05 14:22:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: review edits | `2026-07-05 14:22:00Z` |

---

## 11. Table: `returns`
Registry for product return requests and post-sale refund verification.

| Column Name | Data Type | Key Type | Nullable? | Default | Business Purpose | Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `return_id` | `BIGINT` | PK | NO | `IDENTITY` | Surrogate primary key for returns | `7766` |
| `order_item_id` | `BIGINT` | FK (UK)| NO | - | Unique reference to item in `order_items` | `1087654` |
| `reason` | `VARCHAR(50)`| - | NO | - | Reason check: damaged, wrong_item, size_fit...| `"wrong_item"` |
| `status` | `VARCHAR(30)`| - | NO | `'requested'` | Return state: requested, approved, refunded...| `"refunded"` |
| `refunded_amount`| `NUMERIC(12,2)`| - | NO | `0.00` | Cash amount credited back to consumer | `1209.99` |
| `created_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: return request date | `2026-07-06 09:12:00Z` |
| `updated_at` | `TIMESTAMPTZ`| - | NO | `CURRENT_TIMESTAMP` | Audit timestamp: status update date | `2026-07-08 11:30:00Z` |
