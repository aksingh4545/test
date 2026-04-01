# 🚀 Complete Beginner's Guide to Your Data Pipeline

## 📋 Table of Contents
1. [What is This Project?](#what-is-this-project)
2. [Main Components Explained](#main-components-explained)
3. [How Data Flows](#how-data-flows)
4. [Problems We Faced & Fixed](#problems-we-faced--fixed)
5. [How to Run Everything](#how-to-run-everything)

---

## 🎯 What is This Project?

### Simple Explanation
Imagine you own a big store and you want to track:
- **Who your suppliers are** (people who send you products)
- **What customers are doing** on your website (viewing, clicking, buying)
- **What products you have** in your store

This project collects all that information from different places and stores it in one central database so you can analyze it and make business decisions.

### Real-World Analogy
```
Think of it like a restaurant:
├── Suppliers = Food vendors who deliver ingredients
├── Customers = People ordering food (their behavior)
├── Products = Menu items
└── You = Restaurant owner who wants to see everything in one report
```

---

## 🧩 Main Components Explained

### 1. **Apache Airflow** (The Boss/Manager)
- **What it does**: Schedules and monitors all data tasks
- **Think of it like**: A project manager who makes sure every worker does their job at the right time
- **You access it at**: http://localhost:8083

```
Airflow DAG (workflow) looks like:
Start → Upload Data → Process Data → Transform → Verify → End
```

### 2. **Apache Spark** (The Worker)
- **What it does**: Processes large amounts of data very fast
- **Think of it like**: A super-fast data processor that can handle millions of records
- **Runs inside**: `spark-iceberg` container

### 3. **Apache Iceberg** (The Organizer)
- **What it does**: Organizes data in tables (like Excel sheets but for big data)
- **Think of it like**: A smart filing system that keeps your data organized and easy to query
- **Stores tables in**: MinIO (S3-compatible storage)

### 4. **MinIO** (The Storage Room)
- **What it does**: Stores all your data files (like Google Drive but for your data pipeline)
- **Think of it like**: A warehouse where all your data boxes are stored
- **S3-compatible**: Works like Amazon S3 but runs on your computer
- **You access it at**: http://localhost:9001

### 5. **Kafka** (The Messenger)
- **What it does**: Carries messages/events from one place to another in real-time
- **Think of it like**: A postal service that delivers letters (data events) as they happen
- **Example**: When a customer clicks "buy", Kafka delivers that message to your database

### 6. **Mock Shopify API** (The Fake Online Store)
- **What it does**: Pretends to be Shopify (real e-commerce platform) and provides fake product data
- **Why we created it**: Real Shopify API requires paid subscription (expired after 3 days)
- **Think of it like**: A practice store that gives you sample product data for testing

---

## 🔄 How Data Flows

### Visual Flow
```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA SOURCES (Where data comes from)          │
├─────────────────┬──────────────────┬────────────────────────────┤
│  MinIO (S3)     │     Kafka        │   Mock Shopify API         │
│  - CSV file     │  - User events   │   - Product data           │
│  - Suppliers    │  - Clicks, buys  │   - 500 fake products      │
└────────┬────────┴────────┬─────────┴────────────┬───────────────┘
         │                 │                       │
         ▼                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SPARK PROCESSES THE DATA                      │
│  1. Reads from all 3 sources                                    │
│  2. Cleans and transforms the data                              │
│  3. Writes to Iceberg tables                                    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ICEBERG TABLES (Final Storage)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  suppliers   │  │ user_events  │  │   products   │          │
│  │  (1000 rows) │  │  (110 rows)  │  │  (500 rows)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                        │                                        │
│                        ▼                                        │
│              ┌──────────────────┐                               │
│              │unified_analytics │ (Combined report)             │
│              └──────────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    YOU CAN QUERY THE DATA!
```

### Step-by-Step Data Journey

#### **Path 1: Supplier Data (from CSV file)**
```
1. You have a CSV file: supplier_data_s3_updated.csv
   Contains: supplier_id, name, contact, country, etc.

2. Airflow uploads it to MinIO storage
   Location: s3://supplier-info-data/supplier_data_s3/...

3. Spark reads the CSV from MinIO

4. Spark writes to Iceberg table: analytics.suppliers

5. Result: 1000 supplier records in your database
```

#### **Path 2: User Events (from Kafka)**
```
1. Kafka Producer creates fake user events:
   - user_id: "user_12345"
   - product_id: 1001
   - action: "view", "click", "buy", etc.
   - timestamp: "2024-01-15 10:30:00"

2. Sends 50 events to Kafka topic: user-behavior-events

3. Spark reads events from Kafka

4. Spark writes to Iceberg table: analytics.user_events

5. Result: 110 user behavior records in your database
```

#### **Path 3: Product Data (from Mock Shopify API)**
```
1. Mock Shopify API runs on port 5000
   Generates 500 fake products with:
   - Product name, price, description
   - Variants (sizes, colors)
   - Images, inventory count

2. Spark calls: http://mock-shopify:5000/admin/api/.../products.json

3. Gets 500 products in JSON format

4. Spark writes to Iceberg table: analytics.products

5. Result: 500 product records in your database
```

#### **Path 4: Unified Analytics (Combining Everything)**
```
1. Spark reads all 3 tables:
   - suppliers
   - user_events
   - products

2. Combines them into one report table

3. Creates: analytics.unified_analytics

4. Now you can see everything together!
```

---

## 🐛 Problems We Faced & Fixed

### Problem 1: Python Not Found Error ❌
**Error Message:**
```
java.io.IOException: Cannot run program "/opt/conda/bin/python": 
error=2, No such file or directory
```

**What it means:** Spark was looking for Python in the wrong location

**Why it happened:** The container expected Python at `/opt/conda/bin/python` but it was actually at `/usr/local/bin/python`

**How we fixed it:**
```dockerfile
# In spark/Dockerfile, we created a shortcut (symlink):
RUN mkdir -p /opt/conda/bin && \
    ln -s /usr/local/bin/python /opt/conda/bin/python
```

**Simple explanation:** We created a signpost that says "If you're looking for Python at /opt/conda/bin/python, go to /usr/local/bin/python instead"

---

### Problem 2: Kafka Connector Missing ❌
**Error Message:**
```
Failed to find data source: kafka. Please deploy the application 
as per the deployment section of Structured Streaming + Kafka 
Integration Guide.
```

**What it means:** Spark didn't have the plugin needed to talk to Kafka

**Why it happened:** The download URLs in Dockerfile were wrong (Maven artifact names had typos)

**How we fixed it:**
```dockerfile
# Changed from (WRONG):
spark-sql-kafka-0.10_2.12-3.4.0.jar

# To (CORRECT):
spark-sql-kafka-0-10_2.12-3.4.0.jar
#                    ^  (dash instead of dot)
```

**Simple explanation:** Like trying to download a file with the wrong filename - we fixed the spelling so it downloads correctly.

---

### Problem 3: Shopify API Expired ❌
**Error Message:**
```
Shopify API error: 401 - Invalid API token
```

**What it means:** The Shopify API token stopped working (free trial ended after 3 days)

**Why it happened:** Shopify only gives 3-day free access, then you need to pay

**How we fixed it:**
```python
# Created our own fake Shopify API (scripts/mock_shopify_api.py)
# It generates 500 fake products that look real

# Configuration to use mock API:
USE_MOCK_SHOPIFY=true
MOCK_SHOPIFY_URL=http://mock-shopify:5000
```

**Simple explanation:** Instead of paying for the real store API, we built a practice store that gives us the same type of data for free.

---

### Problem 4: Kafka Connection Error ❌
**Error Message:**
```
Connection refused to localhost:9092
```

**What it means:** Kafka producer couldn't connect to Kafka server

**Why it happened:** Inside Docker containers, you can't use `localhost` - you need to use the container name

**How we fixed it:**
```python
# In produce_kafka_events.py:

# Auto-detect if running inside Docker
if os.path.exists('/.dockerenv'):
    kafka_servers = "kafka:29092"  # Use container name
else:
    kafka_servers = "localhost:9092"  # Use localhost
```

**Simple explanation:** Inside Docker, each container has its own address. Like how you use different room numbers in a hotel.

---

### Problem 5: Table Not Found ❌
**Error Message:**
```
[TABLE_OR_VIEW_NOT_FOUND] The table `spark_catalog.analytics.suppliers` 
cannot be found.
```

**What it means:** SQL query couldn't find the table

**Why it happened:** Wrong table path in the query

**How we fixed it:**
```sql
-- Changed from (WRONG):
SELECT COUNT(*) FROM spark_catalog.analytics.suppliers

-- To (CORRECT):
USE analytics; 
SELECT COUNT(*) FROM suppliers
```

**Simple explanation:** Like using the wrong file path - we fixed it to use the correct location.

---

## 🚀 How to Run Everything

### Step 1: Start All Services
```bash
# Stop any old containers and start fresh
docker-compose down -v

# Start all services (takes 2-3 minutes)
docker-compose up -d
```

**What this does:**
- Starts 8 containers (Airflow, Spark, Kafka, MinIO, etc.)
- Like turning on all the machines in your factory

### Step 2: Check if Everything is Running
```bash
docker-compose ps
```

**You should see:**
```
NAME            STATUS
airflow         Up (healthy)
airflow-db      Up (healthy)
spark-iceberg   Up
kafka           Up
minio           Up
mock-shopify    Up
```

### Step 3: Access Airflow (The Control Panel)
1. Open browser: http://localhost:8083
2. Login: `admin` / `admin`
3. Find `iceberg_data_pipeline` DAG
4. Toggle the switch to enable it
5. Click the "Play" button to run it

### Step 4: Watch the Pipeline Run
1. Click on the DAG name
2. You'll see boxes (tasks) changing colors:
   - ⚪ White = Waiting
   - 🟡 Yellow = Running
   - 🟢 Green = Success
   - 🔴 Red = Failed

### Step 5: Check Your Data
```bash
# Count suppliers
docker exec spark-iceberg spark-sql -e "USE analytics; SELECT COUNT(*) FROM suppliers"
# Should show: 1000

# Count products
docker exec spark-iceberg spark-sql -e "USE analytics; SELECT COUNT(*) FROM products"
# Should show: 500

# Count user events
docker exec spark-iceberg spark-sql -e "USE analytics; SELECT COUNT(*) FROM user_events"
# Should show: 110
```

---

## 📁 Files We Created/Modified

### New Files Created:
1. **`scripts/mock_shopify_api.py`** - Fake Shopify server (generates 500 products)
2. **`SETUP_GUIDE.md`** - Setup instructions
3. **`FIXES_SUMMARY.md`** - List of all fixes
4. **`BEGINNER_GUIDE.md`** - This file!

### Files Modified:
1. **`spark/Dockerfile`** - Fixed Python path + Kafka jar downloads
2. **`scripts/ingest_kafka_events.py`** - Fixed Kafka connection
3. **`scripts/produce_kafka_events.py`** - Auto-detect Docker
4. **`scripts/config.py`** - Added mock API settings
5. **`scripts/ingest_shopify_products.py`** - Support mock API
6. **`dags/iceberg_data_pipeline.py`** - Fixed SQL queries
7. **`docker-compose.yml`** - Added mock-shopify service
8. **`.env`** - Added mock API configuration

---

## 🎓 Key Concepts Explained Simply

### What is a DAG?
```
DAG = Directed Acyclic Graph (fancy name for a workflow)

Simple explanation: A to-do list with dependencies

Example:
Make Breakfast DAG:
  Start
    ↓
  Boil Water
    ↓
  Cook Pasta → Make Sauce (parallel)
    ↓         ↗
  Mix Together
    ↓
  Serve
    ↓
  End
```

### What is ETL?
```
ETL = Extract, Transform, Load

Extract: Get data from somewhere (CSV, API, Kafka)
Transform: Clean it, filter it, combine it
Load: Save it to your database

Example:
Extract: Read supplier CSV file
Transform: Remove duplicates, fix dates
Load: Save to Iceberg table
```

### What is a Container?
```
Container = A lightweight virtual machine

Think of it like: A shipping container for software
- Everything the software needs is inside
- Easy to move around
- Doesn't mess with your main computer

We have 8 containers working together:
┌─────────────────────────────────────┐
│  Your Computer                       │
│  ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │ Airflow │ │ Spark   │ │ Kafka  │ │
│  │Container│ │Container│ │Container│ │
│  └─────────┘ └─────────┘ └────────┘ │
└─────────────────────────────────────┘
```

### What is MinIO/S3?
```
MinIO = Storage service (like Google Drive for data)
S3 = Amazon's storage service (MinIO copies it)

Think of it like: Folders on your computer
But accessible over the network

We create "buckets" (folders):
- supplier-info-data (for CSV files)
- warehouse (for Iceberg tables)
```

### What is Iceberg?
```
Iceberg = A smart way to organize data tables

Think of it like: Excel sheets but for BIG data
- Can handle billions of rows
- Keeps track of changes (version history)
- Fast queries

We have 4 tables:
1. suppliers (who sends us products)
2. user_events (what customers do)
3. products (what we sell)
4. unified_analytics (combined report)
```

---

## 🔧 Troubleshooting Commands

### Check if containers are running:
```bash
docker-compose ps
```

### See logs of a specific service:
```bash
# Airflow logs
docker logs airflow

# Spark logs
docker logs spark-iceberg

# Mock Shopify logs
docker logs mock-shopify
```

### Restart a service:
```bash
docker-compose restart airflow
```

### Stop everything:
```bash
docker-compose down
```

### Clean everything and start fresh:
```bash
docker-compose down -v
docker-compose up -d
```

---

## 📊 What You Have Now

### Working Pipeline:
✅ Uploads supplier data from CSV to MinIO  
✅ Produces Kafka events (user behavior)  
✅ Ingests data from S3, Kafka, and Shopify  
✅ Transforms into unified analytics  
✅ Verifies data with SQL queries  

### Data in Your Database:
| Table | Records | Source |
|-------|---------|--------|
| suppliers | 1,000 | CSV file |
| products | 500 | Mock Shopify API |
| user_events | 110 | Kafka |
| unified_analytics | Combined | All 3 sources |

### Services Running:
| Service | URL | Purpose |
|---------|-----|---------|
| Airflow | http://localhost:8083 | Pipeline control |
| MinIO | http://localhost:9001 | Data storage |
| Spark UI | http://localhost:8082 | Spark monitoring |
| Mock Shopify | http://localhost:5000 | Fake product API |
| Jupyter | http://localhost:8888 | Interactive notebooks |

---

## 🎉 Congratulations!

You now have a fully working data pipeline that:
1. Collects data from multiple sources
2. Processes it with Spark
3. Stores it in Iceberg tables
4. Makes it available for analysis

**Next steps you can try:**
1. Open Airflow and trigger a manual run
2. Query the data using Spark SQL
3. Open Jupyter notebooks and create charts
4. Browse data in MinIO console

**Remember:** All the complex errors we fixed were just small configuration issues - like typos in file names or wrong addresses. Nothing was fundamentally broken!
