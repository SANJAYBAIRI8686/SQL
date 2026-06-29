import csv
import os
import random
import datetime

# Seed for reproducibility
random.seed(42)

WORKSPACE_DIR = "/Users/sanjaykumarbairi/Desktop/Sql Project"
DATASETS_DIR = os.path.join(WORKSPACE_DIR, "datasets")
os.makedirs(DATASETS_DIR, exist_ok=True)

# ----------------------------------------------------------------------------
# 1. GENERATE CATEGORIES
# ----------------------------------------------------------------------------
categories = [
    {"category_id": 1, "name": "Electronics", "slug": "electronics", "description": "Consumer electronics, gadgets and tech devices.", "parent_category_id": ""},
    {"category_id": 2, "name": "Computers & Tablets", "slug": "computers-tablets", "description": "Laptops, desktop systems, and tables.", "parent_category_id": 1},
    {"category_id": 3, "name": "Smart Home", "slug": "smart-home", "description": "Smart plugs, speakers, cameras, and hubs.", "parent_category_id": 1},
    {"category_id": 4, "name": "Apparel", "slug": "apparel", "description": "Clothing, shoes, and wearable accessories.", "parent_category_id": ""},
    {"category_id": 5, "name": "Men's Clothing", "slug": "mens-clothing", "description": "Men's casualwear, activewear, and suits.", "parent_category_id": 4},
    {"category_id": 6, "name": "Women's Clothing", "slug": "womens-clothing", "description": "Women's dresses, activewear, and tops.", "parent_category_id": 4},
    {"category_id": 7, "name": "Home & Kitchen", "slug": "home-kitchen", "description": "Furniture, cookery, and household items.", "parent_category_id": ""},
    {"category_id": 8, "name": "Furniture", "slug": "furniture", "description": "Sofas, dining tables, desks, and bookshelves.", "parent_category_id": 7},
    {"category_id": 9, "name": "Kitchen Appliances", "slug": "kitchen-appliances", "description": "Toasters, air fryers, coffee makers, and ovens.", "parent_category_id": 7},
    {"category_id": 10, "name": "Sports & Outdoors", "slug": "sports-outdoors", "description": "Fitness gear, camping equipment, and sports goods.", "parent_category_id": ""}
]

with open(os.path.join(DATASETS_DIR, "categories.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["category_id", "name", "slug", "description", "parent_category_id"])
    writer.writeheader()
    writer.writerows(categories)

# ----------------------------------------------------------------------------
# 2. GENERATE PRODUCTS
# ----------------------------------------------------------------------------
leaf_categories = [2, 3, 5, 6, 8, 9, 10]

prefixes = ["Apex", "Quantum", "Nexus", "Ultra", "Matrix", "Titan", "Vortex", "Horizon", "Echo", "Sierra", "Summit", "Terra", "Nova", "Stellar"]
adjectives = ["Classic", "Wireless", "Smart", "Premium", "Pro", "Lite", "Comfort", "Heavy-Duty", "Portable", "Ergonomic", "Active"]

category_product_nouns = {
    2: ["Laptop", "Notebook", "Tablet", "Workstation", "Monitor", "Keyboard", "Mouse", "Desktop PC"],
    3: ["Plug", "Camera", "Thermostat", "Speaker", "Lock", "Light Bulb", "Switch", "Hub"],
    5: ["T-Shirt", "Chinos", "Jeans", "Jacket", "Sweater", "Hoodie", "Blazer", "Polo"],
    6: ["Dress", "Blouse", "Leggings", "Skirt", "Cardigan", "Trenchcoat", "Yoga Pants", "Jeans"],
    8: ["Sofa", "Coffee Table", "Dining Table", "Office Chair", "Bookshelf", "Nightstand", "Bed Frame"],
    9: ["Toaster", "Blender", "Coffee Maker", "Air Fryer", "Microwave", "Kettle", "Juicer"],
    10: ["Yoga Mat", "Dumbbells", "Treadmill", "Sleeping Bag", "Tent", "Backpack", "Water Bottle", "Bike Helmet"]
}

# Pricing ranges based on category ID
category_pricing = {
    2: (15.00, 2000.00),    # Computes: mouse to high-end laptops
    3: (10.00, 250.00),     # Smart plugs to smart hubs
    5: (12.00, 300.00),     # T-shirts to leather jackets
    6: (15.00, 350.00),     # Tops to designer trenches
    8: (45.00, 1500.00),    # Office chairs to sectionals
    9: (20.00, 600.00),     # Kettles to high-end coffee machines
    10: (8.00, 1200.00)     # Water bottles to treadmills
}

products = []
product_id = 1
sku_set = set()

# Loop until we reach 520 products to satisfy "500+"
while len(products) < 520:
    cat_id = random.choice(leaf_categories)
    prefix = random.choice(prefixes)
    adj = random.choice(adjectives)
    noun = random.choice(category_product_nouns[cat_id])
    
    name = f"{prefix} {adj} {noun}"
    slug = name.lower().replace(" ", "-")
    
    # Ensure uniqueness of slug/name
    if any(p["name"] == name for p in products):
        continue
        
    sku_prefix = "".join([word[0] for word in name.split()]).upper()
    sku_num = random.randint(1000, 9999)
    sku = f"{sku_prefix}-{sku_num}"
    if sku in sku_set:
        continue
    sku_set.add(sku)
    
    min_p, max_p = category_pricing[cat_id]
    price = round(random.uniform(min_p, max_p), 2)
    # Markup is typically 30% to 60% of cost, so cost is price / 1.3 to 1.6
    cost = round(price / random.uniform(1.3, 1.8), 2)
    
    status = "active"
    if random.random() < 0.03:
        status = "discontinued"
    elif random.random() < 0.02:
        status = "draft"
        
    products.append({
        "product_id": product_id,
        "category_id": cat_id,
        "sku": sku,
        "name": name,
        "slug": slug,
        "description": f"The high-performance {name} designed for optimal durability and style.",
        "price": price,
        "cost": cost,
        "status": status,
        "created_at": "2024-01-01 00:00:00+00",
        "updated_at": "2024-01-01 00:00:00+00"
    })
    product_id += 1

with open(os.path.join(DATASETS_DIR, "products.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["product_id", "category_id", "sku", "name", "slug", "description", "price", "cost", "status", "created_at", "updated_at"])
    writer.writeheader()
    writer.writerows(products)

# ----------------------------------------------------------------------------
# 3. GENERATE CUSTOMERS & ADDRESSES
# ----------------------------------------------------------------------------
first_names = ["John", "Jane", "Robert", "Emily", "Michael", "Sarah", "William", "Jessica", "David", "Ashley", 
               "James", "Mary", "Charles", "Patricia", "Richard", "Jennifer", "Joseph", "Elizabeth", "Thomas", "Linda",
               "Daniel", "Barbara", "Matthew", "Susan", "Anthony", "Margaret", "Mark", "Dorothy", "Donald", "Lisa",
               "Paul", "Nancy", "Steven", "Karen", "Andrew", "Betty", "Kenneth", "Helen", "Joshua", "Sandra"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", 
              "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
              "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson",
              "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores"]

states_data = [
    {"state": "CA", "tax": 0.0825, "weight": 12, "cities": ["Los Angeles", "San Francisco", "San Diego", "San Jose", "Sacramento"]},
    {"state": "TX", "tax": 0.0625, "weight": 9, "cities": ["Houston", "Austin", "Dallas", "San Antonio", "Fort Worth"]},
    {"state": "NY", "tax": 0.0800, "weight": 8, "cities": ["New York City", "Buffalo", "Rochester", "Albany", "Syracuse"]},
    {"state": "FL", "tax": 0.0600, "weight": 7, "cities": ["Miami", "Orlando", "Tampa", "Jacksonville", "Tallahassee"]},
    {"state": "IL", "tax": 0.0725, "weight": 5, "cities": ["Chicago", "Naperville", "Rockford", "Peoria", "Springfield"]},
    {"state": "WA", "tax": 0.0880, "weight": 5, "cities": ["Seattle", "Tacoma", "Spokane", "Bellevue", "Olympia"]},
    {"state": "MA", "tax": 0.0625, "weight": 4, "cities": ["Boston", "Cambridge", "Worcester", "Springfield", "Quincy"]},
    {"state": "PA", "tax": 0.0600, "weight": 4, "cities": ["Philadelphia", "Pittsburgh", "Allentown", "Erie", "Harrisburg"]},
    {"state": "OH", "tax": 0.0575, "weight": 3, "cities": ["Columbus", "Cleveland", "Cincinnati", "Toledo", "Dayton"]},
    {"state": "GA", "tax": 0.0400, "weight": 3, "cities": ["Atlanta", "Savannah", "Augusta", "Athens", "Columbus"]}
]

# We need 10,000+ customers
num_customers = 10500
customers = []
addresses = []
customer_address_map = {} # Maps customer_id to list of address_ids

address_id = 1
for cust_id in range(1, num_customers + 1):
    fn = random.choice(first_names)
    ln = random.choice(last_names)
    email = f"{fn.lower()}.{ln.lower()}.{cust_id}@retailflow.com"
    phone = f"+1-{random.randint(200,999)}-{random.randint(200,999)}-{random.randint(1000,9999)}"
    
    # Signup date: spread over 2023-01-01 to 2025-12-31
    signup_days_ago = random.randint(180, 1000)
    signup_date = datetime.datetime.now() - datetime.timedelta(days=signup_days_ago)
    signup_str = signup_date.strftime("%Y-%m-%d %H:%M:%S+00")
    
    customers.append({
        "customer_id": cust_id,
        "email": email,
        "first_name": fn,
        "last_name": ln,
        "phone": phone,
        "is_active": "true" if random.random() < 0.98 else "false",
        "created_at": signup_str,
        "updated_at": signup_str
    })
    
    # Generate 1 or 2 addresses per customer to keep database normalized and realistic
    num_addr = 2 if random.random() < 0.2 else 1
    customer_address_map[cust_id] = []
    
    for i in range(num_addr):
        state_choice = random.choices(states_data, weights=[s["weight"] for s in states_data], k=1)[0]
        city = random.choice(state_choice["cities"])
        street_num = random.randint(100, 9999)
        street_name = random.choice(["Maple Ave", "Oak St", "Pine Rd", "Broadway", "Main St", "Washington Blvd", "Elm St", "Cedar Ln"])
        addr_line1 = f"{street_num} {street_name}"
        addr_line2 = f"Apt {random.randint(1, 100)}" if random.random() < 0.15 else ""
        zip_code = f"{random.randint(10000, 99999)}"
        addr_type = "both" if num_addr == 1 else ("shipping" if i == 0 else "billing")
        
        addresses.append({
            "address_id": address_id,
            "customer_id": cust_id,
            "address_type": addr_type,
            "recipient_name": f"{fn} {ln}",
            "address_line1": addr_line1,
            "address_line2": addr_line2,
            "city": city,
            "state_province": state_choice["state"],
            "postal_code": zip_code,
            "country": "United States",
            "is_default": "true" if i == 0 else "false",
            "created_at": signup_str,
            "updated_at": signup_str
        })
        customer_address_map[cust_id].append(address_id)
        address_id += 1

with open(os.path.join(DATASETS_DIR, "customers.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["customer_id", "email", "first_name", "last_name", "phone", "is_active", "created_at", "updated_at"])
    writer.writeheader()
    writer.writerows(customers)

with open(os.path.join(DATASETS_DIR, "addresses.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["address_id", "customer_id", "address_type", "recipient_name", "address_line1", "address_line2", "city", "state_province", "postal_code", "country", "is_default", "created_at", "updated_at"])
    writer.writeheader()
    writer.writerows(addresses)

# Map addresses to state tax rates for quick calculation in orders
address_tax_rates = {a["address_id"]: next(s["tax"] for s in states_data if s["state"] == a["state_province"]) for a in addresses}

# ----------------------------------------------------------------------------
# 4. GENERATE INVENTORY
# ----------------------------------------------------------------------------
warehouses = ["US-EAST-01", "US-WEST-01"]
inventory = []
inventory_id = 1

for prod in products:
    if prod["status"] == "draft":
        continue
    # Most items in both warehouses, discontinued items in single warehouse or out
    whs = warehouses if prod["status"] == "active" else [random.choice(warehouses)]
    
    for wh in whs:
        on_hand = random.randint(15, 1200) if prod["status"] == "active" else random.randint(0, 15)
        reserved = int(on_hand * random.uniform(0.01, 0.15)) if on_hand > 0 else 0
        threshold = random.choice([10, 20, 50])
        
        inventory.append({
            "inventory_id": inventory_id,
            "product_id": prod["product_id"],
            "warehouse_code": wh,
            "quantity_on_hand": on_hand,
            "quantity_reserved": reserved,
            "low_stock_threshold": threshold,
            "updated_at": "2026-06-28 12:00:00+00"
        })
        inventory_id += 1

with open(os.path.join(DATASETS_DIR, "inventory.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["inventory_id", "product_id", "warehouse_code", "quantity_on_hand", "quantity_reserved", "low_stock_threshold", "updated_at"])
    writer.writeheader()
    writer.writerows(inventory)

# ----------------------------------------------------------------------------
# 5. GENERATE ORDERS & DEPENDENTS (50,000+ orders)
# ----------------------------------------------------------------------------
# Segregate customers for realistic repeat purchases
# VIP (5%): buy frequently
# Regular (30%): buy occasionally
# One-time (65%): buy once
cust_ids = [c["customer_id"] for c in customers]
random.shuffle(cust_ids)

vip_custs = cust_ids[:500]
regular_custs = cust_ids[500:3500]
onetime_custs = cust_ids[3500:]

# Set Date boundaries
start_date = datetime.date(2024, 7, 1)
end_date = datetime.date(2026, 6, 28)
total_days = (end_date - start_date).days

# Target: 52,000 orders
orders = []
order_items = []
payments = []
shipments = []
returns = []
reviews = []

order_id = 1
order_item_id = 1
payment_id = 1
shipment_id = 1
return_id = 1
review_id = 1

# Generate a list of dates weighted seasonally
# Weight factors per month:
seasonal_weights = {
    1: 0.8, 2: 0.8, 3: 0.9, 4: 0.9, 5: 1.0, 6: 1.1,
    7: 1.0, 8: 0.9, 9: 1.0, 10: 1.1, 11: 1.8, 12: 2.2
}

# Pre-populate dates based on seasonal weights
weighted_days = []
for d in range(total_days + 1):
    curr_date = start_date + datetime.timedelta(days=d)
    weight = seasonal_weights[curr_date.month]
    weighted_days.append((curr_date, weight))

dates_pool = random.choices([wd[0] for wd in weighted_days], weights=[wd[1] for wd in weighted_days], k=52000)
dates_pool.sort() # Keep chronological logic clean

active_products = [p for p in products if p["status"] == "active"]
review_pairs = set()

for order_date in dates_pool:
    # Select customer based on cohort
    cohort = random.choices(["vip", "regular", "onetime"], weights=[30, 50, 20], k=1)[0]
    if cohort == "vip":
        cust_id = random.choice(vip_custs)
    elif cohort == "regular":
        cust_id = random.choice(regular_custs)
    else:
        cust_id = random.choice(onetime_custs)
        
    addr_ids = customer_address_map[cust_id]
    ship_addr_id = addr_ids[0]
    bill_addr_id = addr_ids[1] if len(addr_ids) > 1 else ship_addr_id
    
    # Calculate tax rate based on shipping address
    tax_rate = address_tax_rates[ship_addr_id]
    
    # Generate Order Items (1 to 4 items)
    num_items = random.choices([1, 2, 3, 4], weights=[60, 25, 10, 5], k=1)[0]
    items_to_add = random.sample(active_products, num_items)
    
    subtotal = 0.00
    order_items_cache = []
    
    for prod in items_to_add:
        qty = random.choices([1, 2, 3, 5], weights=[80, 15, 4, 1], k=1)[0]
        u_price = prod["price"]
        # 10% chance of a discount
        discount = 0.00
        if random.random() < 0.10:
            discount = round(u_price * random.choice([0.05, 0.10, 0.15]), 2)
            
        net = round((qty * u_price) - discount, 2)
        subtotal += net
        
        order_items_cache.append({
            "order_item_id": order_item_id,
            "order_id": order_id,
            "product_id": prod["product_id"],
            "quantity": qty,
            "unit_price": u_price,
            "discount_amount": discount
        })
        order_item_id += 1
        
    tax = round(subtotal * tax_rate, 2)
    # Free shipping on orders over $100
    shipping = 0.00 if subtotal > 100.00 else 9.99
    total = round(subtotal + tax + shipping, 2)
    
    # Determine status
    # pending, payment_failed, processing, partially_shipped, shipped, delivered, cancelled, returned
    status_choice = random.choices(
        ["pending", "payment_failed", "processing", "shipped", "delivered", "cancelled", "returned"],
        weights=[2, 3, 10, 10, 68, 4, 3],
        k=1
    )[0]
    
    order_hour = random.randint(0, 23)
    order_min = random.randint(0, 59)
    order_sec = random.randint(0, 59)
    order_datetime = datetime.datetime.combine(order_date, datetime.time(order_hour, order_min, order_sec))
    order_datetime_str = order_datetime.strftime("%Y-%m-%d %H:%M:%S+00")
    
    # Write order header
    orders.append({
        "order_id": order_id,
        "customer_id": cust_id,
        "shipping_address_id": ship_addr_id,
        "billing_address_id": bill_addr_id,
        "status": status_choice,
        "total_amount": total,
        "tax_amount": tax,
        "shipping_amount": shipping,
        "ordered_at": order_datetime_str,
        "updated_at": order_datetime_str
    })
    
    # Add order items to list
    order_items.extend(order_items_cache)
    
    # Generate Payments
    pay_method = random.choice(['credit_card', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer'])
    pay_gateway = random.choices(['stripe', 'paypal', 'adyen'], weights=[70, 20, 10], k=1)[0]
    pay_ref = f"txn_{order_id}_{random.randint(100000, 999999)}"
    pay_status = "captured"
    if status_choice == "payment_failed":
        pay_status = "failed"
    elif status_choice == "cancelled":
        pay_status = "voided" if random.random() < 0.5 else "failed"
    elif status_choice == "returned":
        pay_status = "refunded"
        
    payments.append({
        "payment_id": payment_id,
        "order_id": order_id,
        "payment_method": pay_method,
        "payment_gateway": pay_gateway,
        "transaction_reference": pay_ref,
        "amount": total,
        "status": pay_status,
        "created_at": (order_datetime + datetime.timedelta(minutes=2)).strftime("%Y-%m-%d %H:%M:%S+00"),
        "updated_at": (order_datetime + datetime.timedelta(minutes=2)).strftime("%Y-%m-%d %H:%M:%S+00")
    })
    payment_id += 1
    
    # Generate Shipments
    if status_choice in ["shipped", "delivered", "returned"]:
        carrier = random.choice(["FedEx", "UPS", "DHL", "USPS"])
        tracking = f"1Z{random.randint(100000, 999999)}A{random.randint(10, 99)}1234{order_id}"
        ship_status = "delivered" if status_choice in ["delivered", "returned"] else "in_transit"
        
        ship_days = random.randint(1, 2)
        shipped_time = order_datetime + datetime.timedelta(days=ship_days, hours=random.randint(1, 5))
        
        delivered_time = ""
        if ship_status == "delivered":
            deliv_days = random.randint(2, 4)
            delivered_time = (shipped_time + datetime.timedelta(days=deliv_days, hours=random.randint(1, 5))).strftime("%Y-%m-%d %H:%M:%S+00")
            
        shipments.append({
            "shipment_id": shipment_id,
            "order_id": order_id,
            "carrier": carrier,
            "tracking_number": tracking,
            "status": ship_status,
            "estimated_delivery": (order_datetime + datetime.timedelta(days=5)).strftime("%Y-%m-%d %H:%M:%S+00"),
            "shipped_at": shipped_time.strftime("%Y-%m-%d %H:%M:%S+00"),
            "delivered_at": delivered_time,
            "created_at": order_datetime_str,
            "updated_at": order_datetime_str
        })
        shipment_id += 1
        
    # Generate Returns (Only for "returned" orders - return rate constraint verified here)
    if status_choice == "returned":
        # Return a random item from the order
        returned_item = random.choice(order_items_cache)
        ret_reason = random.choice(['damaged', 'defective', 'wrong_item', 'size_fit', 'buyer_remorse', 'late_delivery'])
        ret_status = "refunded"
        
        # Calculate refund net amount
        qty_r = returned_item["quantity"]
        pr_r = returned_item["unit_price"]
        disc_r = returned_item["discount_amount"]
        refund_amt = round((qty_r * pr_r) - disc_r, 2)
        
        returns.append({
            "return_id": return_id,
            "order_item_id": returned_item["order_item_id"],
            "reason": ret_reason,
            "status": ret_status,
            "refunded_amount": refund_amt,
            "created_at": (order_datetime + datetime.timedelta(days=7)).strftime("%Y-%m-%d %H:%M:%S+00"),
            "updated_at": (order_datetime + datetime.timedelta(days=9)).strftime("%Y-%m-%d %H:%M:%S+00")
        })
        return_id += 1
        
    # Generate Reviews (30% chance for delivered or returned orders)
    if status_choice in ["delivered", "returned"] and random.random() < 0.30:
        reviewed_item = random.choice(order_items_cache)
        review_pair = (reviewed_item["product_id"], cust_id)
        if review_pair not in review_pairs:
            review_pairs.add(review_pair)
            
            # SKEW review ratings: 5-stars (50%), 4-stars (30%), 3-stars (10%), 2-stars (5%), 1-star (5%)
            rating = random.choices([5, 4, 3, 2, 1], weights=[50, 30, 10, 5, 5], k=1)[0]
            titles = {
                5: "Excellent!", 4: "Very Good", 3: "Average", 2: "Disappointed", 1: "Awful product"
            }
            comments = {
                5: "Exceeded my expectations, highly recommended!",
                4: "Good value for money, functions well.",
                3: "Decent but has some minor issues.",
                2: "Not as described, quality is subpar.",
                1: "Stopped working after two days, avoid!"
            }
            
            reviews.append({
                "review_id": review_id,
                "product_id": reviewed_item["product_id"],
                "customer_id": cust_id,
                "rating": rating,
                "title": titles[rating],
                "comment": comments[rating],
                "created_at": (order_datetime + datetime.timedelta(days=6)).strftime("%Y-%m-%d %H:%M:%S+00"),
                "updated_at": (order_datetime + datetime.timedelta(days=6)).strftime("%Y-%m-%d %H:%M:%S+00")
            })
            review_id += 1

    order_id += 1

# Save generated lists to CSVs
datasets_map = {
    "orders.csv": (orders, ["order_id", "customer_id", "shipping_address_id", "billing_address_id", "status", "total_amount", "tax_amount", "shipping_amount", "ordered_at", "updated_at"]),
    "order_items.csv": (order_items, ["order_item_id", "order_id", "product_id", "quantity", "unit_price", "discount_amount"]),
    "payments.csv": (payments, ["payment_id", "order_id", "payment_method", "payment_gateway", "transaction_reference", "amount", "status", "created_at", "updated_at"]),
    "shipments.csv": (shipments, ["shipment_id", "order_id", "carrier", "tracking_number", "status", "estimated_delivery", "shipped_at", "delivered_at", "created_at", "updated_at"]),
    "returns.csv": (returns, ["return_id", "order_item_id", "reason", "status", "refunded_amount", "created_at", "updated_at"]),
    "reviews.csv": (reviews, ["review_id", "product_id", "customer_id", "rating", "title", "comment", "created_at", "updated_at"])
}

for filename, (data, headers) in datasets_map.items():
    with open(os.path.join(DATASETS_DIR, filename), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)

print("SUCCESS: Realistic synthetic e-commerce data generation complete.")
