# OmniShop E-Commerce Core Database Schema

This repository contains the design, schema, and performance tuning configurations for **OmniShop**, a production-grade relational database optimized for high-throughput retail operations. Built using **PostgreSQL**, it is fully compatible with **Google Cloud SQL** and designed to easily integrate with analytical layers (e.g. Google Cloud Anthos federated queries or BigQuery BigTable external integrations for high-scale clickstream analysis).

---

## 1. Database Architecture & ER Diagram
The database is structured in **Third Normal Form (3NF)** to eliminate redundancy and maintain database write integrity during high checkout volumes.

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

## 2. File Repository Structure

*   [schema.sql](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/schema.sql): Complete DDL scripts constructing the tables, constraints, default states, and column annotations.
*   [indexing_strategy.md](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/indexing_strategy.md): The technical design behind database performance, outlining functional, composite, and partial indexes.
*   [data_dictionary.md](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/data_dictionary.md): Comprehensive listing of all attributes, types, rules, and example values.
*   [business_rules.md](file:///Users/sanjaykumarbairi/Desktop/Sql%20Project/business_rules.md): Explicit documentation of financial, structural, and shipping invariants.

---

## 3. Production Deployment Notes (Google Cloud SQL)

When migrating this schema to Google Cloud SQL (PostgreSQL), execute the following enterprise best practices:

### 3.1 Connection Security
1.  Disable all public IP routing to the Cloud SQL instance.
2.  Enable **Private IP (PSC/VPC Peering)** to ensure only internal microservices (deployed on GKE or Compute Engine) can connect.
3.  Utilize the **Cloud SQL Auth Proxy** in Kubernetes sidecars to automate TLS handshake and IAM credentials-based authorization.

### 3.2 Anthos & Hybrid Integration
For massive catalogs or analytics:
*   **BigTable Integration:** Read-heavy transactional tables like real-time `inventory` can be cached/mapped to BigTable for sub-millisecond lookups.
*   **BigQuery Federated Queries:** Use External Connections in BigQuery to query PostgreSQL directly (`EXTERNAL_QUERY("project.us.connection", "SELECT ... FROM core.orders")`) to compile BI dashboards without taxing the transactional engine.
*   **Replication:** Configure Read Replicas inside Cloud SQL to offload `SELECT` reporting from primary checkout nodes.
