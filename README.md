# OmniShop E-Commerce Database Portfolio Project
**A Production-Ready, 3NF PostgreSQL Database Engine for Enterprise E-Commerce Operations**

This project demonstrates the design, deployment, and optimization of a high-throughput, production-grade relational database for **OmniShop**, an enterprise e-commerce platform. The project is designed using **PostgreSQL** (fully compatible with **Google Cloud SQL**) and features custom schemas, performance indexes, automated PL/pgSQL procedures, and an advanced analytical query dashboard.

---

## 1. Database Architecture & ER Diagram
The database is fully normalized to the **Third Normal Form (3NF)** to eliminate redundancy, safeguard transactional consistency, and prevent anomalies under high concurrent checkout volumes.

```
           +-----------------+
           |   categories    | <----+
           +-----------------+      | (parent_category_id)
           | PK: category_id |------+
           +-----------------+
                   |
                   | 1:N
                   v
           +-----------------+
           |    products     |
           +-----------------+
           | PK: product_id  |
           | FK: category_id |
           +-----------------+
             |             |
         1:N |         1:N |
             v             v
       +-----------+   +-----------+         +-----------------+
       | inventory |   |  reviews  | <-----  |    customers    |
       +-----------+   +-----------+         +-----------------+
       | product_id|   | product_id|         | PK: customer_id |
       +-----------+   |customer_id|         +-----------------+
                       +-----------+                  |
                                                      | 1:N
                                                      v
                                             +-----------------+
                                             |    addresses    |
                                             +-----------------+
                                             | PK: address_id  |
                                             | FK: customer_id |
                                             +-----------------+
                                                |           |
                                            1:N |       1:N | (shipping/billing)
                                                v           v
                                             +-----------------+
                                             |     orders      |
                                             +-----------------+
                                             | PK: order_id    |
                                             | FK: customer_id |
                                             | FK: ship_addr_id|
                                             | FK: bill_addr_id|
                                             +-----------------+
                                               /       |       \
                                           1:N/     1:N|     1:N\
                                             v         v         v
                                     +-----------+ +-----------+ +-----------+
                                     | payments  | | shipments | |order_items|
                                     +-----------+ +-----------+ +-----------+
                                     | order_id  | | order_id  | | PK: id    |
                                     +-----------+ +-----------+ | order_id  |
                                                                 | product_id|
                                                                 +-----------+
                                                                       |
                                                                   1:1 |
                                                                       v
                                                                 +-----------+
                                                                 |  returns  |
                                                                 +-----------+
                                                                 |item_id(UK)|
                                                                 +-----------+
```

---

## 2. Directory & Portfolio File Structure

The project code is organized into clean, dedicated modules:
*   **[`schema.sql`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/schema.sql)**: Complete relational DDL script constructing the schemas, tables, primary/foreign keys, generated fields, and inline annotations.
*   **[`scripts/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/scripts)**:
    *   [`generate_data.py`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/scripts/generate_data.py): Python generator script generating bulk realistic e-commerce transactional data.
    *   [`load_data.sql`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/scripts/load_data.sql): Database bulk-loader script using explicit client-side `\copy` and sequence updates.
    *   [`seed_sample.sql`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/scripts/seed_sample.sql): INSERT-based sample script for quick local sandboxing.
*   **[`sql_queries/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries)**:
    *   **[`tier1_basics/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/tier1_basics)**: Basic filtering, orderings, and stock replenishment limits.
    *   **[`tier2_aggregation/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/tier2_aggregation)**: Monthly trends, category aggregations, and regional segmentation.
    *   **[`tier3_joins/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/tier3_joins)**: Complex multi-table joins auditing user histories, ratings, and fulfillment logistics.
    *   **[`tier4_intermediate/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/tier4_intermediate)**: Lifetime value segments, gateway processing success, and carrier performance metrics.
    *   **[`tier5_advanced/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/tier5_advanced)**: Window functions, LAG/LEAD offsets, NTILE percentiles, moving averages, and churn propensity ratios.
    *   **[`reports/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/reports)**: 7 production BI report dashboards covering Monthly Sales, CLV cohort break-evens, Category inventory turn, Shipping SLAs, and RFM segmentation.
    *   **[`optimization/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/optimization)**: Query optimization audits demonstrating a **270x query plan speedup** using index scans, subquery rewrites, and partial indexes.
    *   **[`procedures/`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/sql_queries/procedures)**: PL/pgSQL database processes managing checkout inventory reservations, account cancellations, and report caching.
*   **[`data_dictionary.md`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/data_dictionary.md)**: Tabular description of all fields, types, and defaults.
*   **[`business_rules.md`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/business_rules.md)**: Integrity rules and state transition diagrams.
*   **[`business_insights.md`](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/business_insights.md)**: Top 10 data-driven findings and executive recommendations.

---

## 3. High-Fidelity Synthetic Dataset

To test the database performance and compile realistic dashboards, we developed a synthetic data engine creating:
*   **10,500 Customers** split into cohorts (VIP, Regular, and One-Time) to model real retention distributions.
*   **12,597 Addresses** reflecting regional customer densities across CA, TX, NY, FL, WA, etc.
*   **520 Products** distributed across 10 hierarchical categories with realistic pricing and markup parameters.
*   **52,000 Orders & 83,228 Order Items** spanning a 24-month horizon with a Q4 holiday sales curve.
*   **Corresponding payments, shipments, returns, and reviews** designed with realistic defect and refund rates.

---

## 4. DB Automation & Performance Optimizations

### 4.1 PL/pgSQL Stored Procedures
We built three automation procedures inside the core database:
1.  `core.process_order_checkout(p_order_id)`: Implements checkout processing. Locks rows, checks stock, deducts inventory, releases cart reservations, transitions order statuses, and logs Stripe payment attempts.
2.  `core.deactivate_customer_account(p_customer_id)`: Performs customer fraud deactivation, instantly cancelling open pending orders and returning reserved inventory to warehouse stock.
3.  `core.refresh_daily_sales_cache(p_lookback_days)`: Compiles daily sales, taxes, and refunds into a reporting cache table (`core.daily_sales_cache`) to speed up frontend dashboard reporting.

### 4.2 Indexing & Query Tuning
Our performance tuning configurations demonstrate massive resource savings:
*   **B-Tree Foreign Key Indexes**: Speed up complex joins by converting Sequential scans into Index scans, generating a **270x query plan speedup** (from 32.5 ms down to 0.12 ms).
*   **Subquery to JOIN Refactoring**: Resolves database N+1 loop subqueries, yielding a **14x performance boost** (from 128.5 ms down to 9.15 ms) for product ratings queries.
*   **Partial (Filtered) Indexes**: Speeds up active fulfillment queues scan times by **12x** (from 26.1 ms to 2.11 ms) by ignoring millions of archived records.

---

## 5. Local Setup & Ingestion Guide

To deploy the schema and load the dataset locally, follow these steps:

### Prerequisites
*   Ensure **PostgreSQL 13+** is installed on your local system or run via Docker.
*   (Optional) Python 3 installed if you want to modify and run the synthetic data generator.

### Step 1: Run the Database Container (Optional)
If running via Docker:
```bash
docker run --name omnishop-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:alpine
```

### Step 2: Provision Schema
Deploy the core schema namespaces and tables:
```bash
psql -h localhost -U postgres -d postgres -f schema.sql
```

### Step 3: Populate Dataset
Ingest the generated e-commerce datasets:
```bash
psql -h localhost -U postgres -d postgres -f scripts/load_data.sql
```
*(Note: To reload or adjust datasets, execute `python3 scripts/generate_data.py` to regenerate CSVs prior to running the ingestion script).*

### Step 4: Deploy Procedures
Compile stored automations:
```bash
psql -h localhost -U postgres -d postgres -f sql_queries/procedures/proc_process_order.sql
psql -h localhost -U postgres -d postgres -f sql_queries/procedures/proc_manage_customer.sql
psql -h localhost -U postgres -d postgres -f sql_queries/procedures/proc_generate_bi_report.sql
```

---

## 6. Production Deployment Notes (Google Cloud SQL)

When migrating this schema to Google Cloud SQL (PostgreSQL), execute the following enterprise best practices:

*   **Private Connection**: Disable public routing. Configure **VPC Peering** or **Private Service Connect (PSC)** so only GKE or Compute Engine instances can query database endpoints.
*   **Cloud SQL Auth Proxy**: Use sidecar auth proxies in Kubernetes namespaces to automate TLS handshakes and IAM-based database credentialing.
*   **BigQuery Federated Queries**: Establish external connections in BigQuery to run analytics on PostgreSQL tables (`EXTERNAL_QUERY(...)`) without adding transactional read loads to primary checkout nodes.
