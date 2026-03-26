# Spark-Iceberg Data Pipeline - Complete Implementation Guide

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [What We Built](#what-we-built)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [How Iceberg Works](#how-iceberg-works)
5. [Errors We Faced & Solutions](#errors-we-faced--solutions)
6. [Complete Workflow](#complete-workflow)
7. [Interview Explanation](#interview-explanation)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                     │
├─────────────────┬─────────────────┬─────────────────────────────────────┤
│   S3 (MinIO)    │     Kafka       │         Shopify API                 │
│   Supplier CSV  │  User Events    │      Products (105 items)           │
└────────┬────────┴────────┬────────┴──────────────┬──────────────────────┘
         │                 │                       │
         ▼                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    SPARK PROCESSING LAYER                                │
│              (PySpark Scripts with Iceberg Connector)                    │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │ ingest_s3_       │  │ ingest_kafka_    │  │ ingest_shopify_  │      │
│  │ supplier.py      │  │ events.py        │  │ products.py      │      │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘      │
│                                                                          │
│                          ▼                                               │
│              ┌──────────────────────┐                                    │
│              │ transform_unified_   │                                    │
│              │ view.py              │                                    │
│              └──────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    ICEBERG CATALOG (REST)                                │
│              Metadata Management & Schema Tracking                       │
│                      Port: 8181                                          │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER (MinIO)                                 │
│              s3://warehouse/analytics/                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │ suppliers/   │  │ user_events/ │  │ products/    │                  │
│  │ (Parquet +   │  │ (Parquet +   │  │ (Parquet +   │                  │
│  │  Metadata)   │  │  Metadata)   │  │  Metadata)   │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
│                        │                                                 │
│                        ▼                                                 │
│              ┌──────────────────┐                                        │
│              │unified_analytics/│                                        │
│              │ (Transformed)    │                                        │
│              └──────────────────┘                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## What We Built

### Infrastructure (Docker Compose)
| Service | Purpose | Port |
|---------|---------|------|
| **spark-iceberg** | PySpark processing with Iceberg | 8888, 8080, 10000-10001 |
| **iceberg-rest** | Iceberg REST Catalog (metadata) | 8181 |
| **minio** | S3-compatible object storage | 9000, 9001 |
| **kafka** | Message broker for streaming | 9092 |
| **zookeeper** | Kafka coordination | 2181 |
| **mc** | MinIO client (bucket management) | - |

### Data Tables (Iceberg)
| Table | Source | Records | Purpose |
|-------|--------|---------|---------|
| `suppliers` | S3 CSV | 1,000 | Supplier order data |
| `user_events` | Kafka | 50 | User behavior tracking |
| `products` | Shopify API | 105 | E-commerce product catalog |
| `unified_analytics` | Transformed | 255 | Joined analytics view |

---

## Step-by-Step Setup

### Step 1: Docker Infrastructure
```bash
# Start all services
docker-compose up -d

# Verify all containers running
docker-compose ps
```

**What this does:**
- Creates isolated network `iceberg_net`
- Starts 6 containers that communicate internally
- MinIO creates `warehouse` bucket automatically
- Kafka creates topic `user-behavior-events`

### Step 2: Upload Source Data to MinIO
```bash
# Copy CSV to container
docker cp supplier_data_s3_updated.csv spark-iceberg:/tmp/

# Copy to MinIO via mc container
docker cp spark-iceberg:/tmp/supplier_data_s3_updated.csv mc:/tmp/
docker exec mc /usr/bin/mc cp /tmp/supplier_data_s3_updated.csv \
    minio/supplier-info-data/supplier_data_s3/
```

**Why:** Spark needs to read CSV from S3. MinIO simulates AWS S3.

### Step 3: Create Kafka Topic & Produce Events
```bash
# Create topic
docker exec kafka kafka-topics --create \
    --topic user-behavior-events \
    --bootstrap-server localhost:9092 \
    --partitions 3 --replication-factor 1

# Produce test events (from host)
python scripts/produce_kafka_events.py --count 50 --servers localhost:9092
```

### Step 4: Run Ingestion Pipelines

#### A. S3 Supplier Ingestion
```bash
docker exec -it spark-iceberg python3 \
    /home/iceberg/scripts/ingest_s3_supplier.py
```

**What happens:**
1. Spark reads CSV from `s3a://supplier-info-data/supplier_data_s3/`
2. Creates Iceberg table `spark_catalog.analytics.suppliers`
3. Writes 1,000 rows with metadata columns (`loaded_at`, `source`)

#### B. Kafka Events Ingestion
```bash
docker exec -it spark-iceberg python3 \
    /home/iceberg/scripts/ingest_kafka_events.py
```

**What happens:**
1. Spark reads from Kafka topic `user-behavior-events`
2. Parses JSON messages
3. Creates Iceberg table `spark_catalog.analytics.user_events`
4. Writes 50 events partitioned by date

#### C. Shopify Products Ingestion
```bash
docker exec -it spark-iceberg python3 \
    /home/iceberg/scripts/ingest_shopify_products.py
```

**What happens:**
1. Python script calls Shopify API (`GET /admin/api/2024-01/products.json`)
2. Fetches 105 products with nested variants, options, images
3. Saves to temp JSON file
4. Spark reads JSON and creates Iceberg table with complex nested schema
5. Writes 105 products

### Step 5: Run Transformation
```bash
docker exec -it spark-iceberg python3 \
    /home/iceberg/scripts/transform_unified_view.py
```

**What happens:**
1. Creates 4 views:
   - `product_summary` - Products with engagement metrics
   - `daily_metrics` - Daily aggregated actions
   - `user_behavior` - Per-user activity patterns
   - `product_inventory` - Flattened variant data
2. Joins all sources into `unified_analytics`
3. Writes 255 transformed records

---

## How Iceberg Works

### Traditional Parquet vs Iceberg

**Traditional Parquet:**
```
s3://data/table/
├── data-00001.parquet
├── data-00002.parquet
└── _SUCCESS
```
- No schema tracking
- No ACID transactions
- Full table scans for updates

**Iceberg:**
```
s3://warehouse/analytics/products/
├── metadata/
│   ├── 00000-abc123.metadata.json    ← Table schema
│   ├── 00001-def456.metadata.json    ← Schema evolution
│   ├── snap-12345-abc123.avro        ← Snapshot tracking
│   └── version-hint.text             ← Current snapshot
├── data/
│   └── 00000-0-abc123-00001.parquet  ← Actual data
└── statistics/
    └── 00000-abc123.parquet.stats    ← Column statistics
```

### Key Iceberg Features We Used

#### 1. **Schema Evolution**
```python
# Shopify data had extra fields in variants
# Iceberg automatically merged new fields into existing schema
enriched_df.writeTo("spark_catalog.analytics.products")\
    .createOrReplace()  # Handles schema changes
```

#### 2. **Time Travel**
```sql
-- Query data as of specific snapshot
SELECT * FROM spark_catalog.analytics.products 
TIMESTAMP AS OF '2024-03-27 01:00:00'

-- View snapshot history
SELECT * FROM spark_catalog.analytics.products.history
```

#### 3. **ACID Transactions**
```python
# Multiple writers can safely append
df1.writeTo("table").append()  # Transaction 1
df2.writeTo("table").append()  # Transaction 2
# No data corruption
```

#### 4. **Partition Evolution**
```python
# Table created with date partitioning
PARTITIONED BY (bucket(16, event_date))
# Can change partition scheme without rewriting data
```

### Iceberg Catalog Architecture

```
┌─────────────────┐
│   Spark SQL     │
│  SELECT * FROM  │
│   products      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Iceberg Spark  │
│    Catalog      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  REST Catalog   │  ← Metadata stored here
│  (port 8181)    │     (schema, snapshots)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     MinIO       │  ← Actual data stored here
│  (S3 bucket)    │     (Parquet files)
└─────────────────┘
```

---

## Errors We Faced & Solutions

### Error 1: S3A FileSystem Not Found
```
java.lang.ClassNotFoundException: Class org.apache.hadoop.fs.s3a.S3AFileSystem not found
```

**Cause:** Spark container missing Hadoop AWS libraries

**Solution:** Added JARs to Dockerfile
```dockerfile
RUN curl -L -o /opt/spark/jars/hadoop-aws-3.3.4.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

RUN curl -L -o /opt/spark/jars/aws-java-sdk-bundle-1.12.262.jar \
    https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
```

### Error 2: Iceberg Namespace Not Found
```
org.apache.iceberg.exceptions.NoSuchNamespaceException: 
Cannot create table prod.analytics.suppliers. Namespace prod.analytics does not exist
```

**Cause:** Iceberg requires explicit namespace creation

**Solution:** Create database first
```python
spark.sql("CREATE DATABASE IF NOT EXISTS spark_catalog.analytics")
```

### Error 3: Schema Mismatch
```
[INCOMPATIBLE_DATA_FOR_TABLE.CANNOT_FIND_DATA] 
Cannot find data for the output column `contact_name`
```

**Cause:** CSV schema didn't match table schema

**Solution:** Updated table schema to match actual CSV columns
```python
# Changed from complex schema to actual CSV columns
CREATE TABLE suppliers (
    supplier_id INT,
    supplier_name STRING,
    order_id INT,
    order_date DATE,
    amount INT,
    currency STRING,
    country STRING,
    id INT,
    loaded_at TIMESTAMP,
    source STRING
)
```

### Error 4: Shopify API Pagination
```
{"errors":{"page":"page cannot be passed. See shopify.dev/api/usage/pagination-rest"}}
```

**Cause:** Shopify deprecated page-based pagination

**Solution:** Use cursor-based pagination with Link header
```python
while next_page_url:
    response = requests.get(next_page_url, headers=headers, params={"limit": 250})
    link_header = response.headers.get("Link", "")
    if 'rel="next"' in link_header:
        next_page_url = extract_next_url(link_header)
    else:
        break
```

### Error 5: Kafka Topic Not Found
```
org.apache.kafka.common.errors.UnknownTopicOrPartitionException: 
This server does not host this topic-partition
```

**Cause:** Topic auto-creation disabled, topic doesn't exist

**Solution:** Create topic before ingestion
```bash
docker exec kafka kafka-topics --create \
    --topic user-behavior-events \
    --bootstrap-server localhost:9092 \
    --partitions 3 --replication-factor 1
```

### Error 6: REST Catalog Metadata Cache
```
org.apache.iceberg.exceptions.NoSuchTableException: 
Location does not exist: s3://warehouse/analytics/products/metadata/...
```

**Cause:** REST catalog cached old table metadata after we deleted files

**Solution:** Full restart with volume cleanup
```bash
docker-compose down -v  # -v removes volumes
docker-compose up -d
```

### Error 7: SQL Function `lit()` Not Found
```
[UNRESOLVED_ROUTINE] Cannot resolve function `lit` on search path
```

**Cause:** `lit()` is DataFrame API, not SQL function

**Solution:** Use string literal in SQL
```python
# Wrong
spark.sql("SELECT lit('transformed') as source")

# Correct
spark.sql("SELECT 'transformed' as source")
```

---

## Complete Workflow

### Data Flow Diagram
```
┌──────────────────────────────────────────────────────────────────┐
│                    EXECUTION ORDER                                │
└──────────────────────────────────────────────────────────────────┘

1. docker-compose up -d
   └─> Starts: Spark, Iceberg REST, MinIO, Kafka, Zookeeper

2. Upload supplier CSV to MinIO
   └─> s3://supplier-info-data/supplier_data_s3/supplier_data_s3_updated.csv

3. Create Kafka topic & produce events
   └─> Topic: user-behavior-events (50 messages)

4. Run ingest_s3_supplier.py
   └─> spark_catalog.analytics.suppliers (1,000 records)

5. Run ingest_kafka_events.py
   └─> spark_catalog.analytics.user_events (50 records)

6. Run ingest_shopify_products.py
   └─> spark_catalog.analytics.products (105 records)

7. Run transform_unified_view.py
   └─> spark_catalog.analytics.unified_analytics (255 records)

8. Query results
   └─> spark-sql or Python with Iceberg config
```

### Configuration Files

#### docker-compose.yml
```yaml
services:
  spark-iceberg:
    image: tabulario/spark-iceberg
    build: spark/  # Custom Dockerfile with extra JARs
    volumes:
      - ./warehouse:/home/iceberg/warehouse
      - ./scripts:/home/iceberg/scripts
    environment:
      - AWS_ACCESS_KEY_ID=admin
      - AWS_SECRET_ACCESS_KEY=password
      
  rest:
    image: apache/iceberg-rest-fixture
    environment:
      - CATALOG_WAREHOUSE=s3://warehouse/
      - CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO
      
  minio:
    image: minio/minio
    command: server /data --console-address :9001
    
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      - KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
```

#### scripts/config.py
```python
class Config:
    # Iceberg
    ICEBERG_REST_URI = "http://rest:8181"
    ICEBERG_WAREHOUSE = "s3://warehouse/"
    ICEBERG_CATALOG_NAME = "spark_catalog"
    
    # MinIO
    AWS_ACCESS_KEY_ID = "admin"
    AWS_SECRET_ACCESS_KEY = "password"
    S3_ENDPOINT = "http://minio:9000"
    
    # Kafka
    KAFKA_BOOTSTRAP_SERVERS = "kafka:29092"
    KAFKA_TOPIC = "user-behavior-events"
    
    # Shopify
    SHOPIFY_SHOP_NAME = "my-data-pipeline-test"
    SHOPIFY_ACCESS_TOKEN = "shpat_xxx"
```

#### Spark Session Configuration
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder\
    .appName("IcebergPipeline")\
    .master("spark://spark-iceberg:7077")\
    .config("spark.sql.catalog.spark_catalog", 
            "org.apache.iceberg.spark.SparkCatalog")\
    .config("spark.sql.catalog.spark_catalog.type", "rest")\
    .config("spark.sql.catalog.spark_catalog.uri", "http://rest:8181")\
    .config("spark.sql.catalog.spark_catalog.warehouse", "s3://warehouse/")\
    .config("spark.sql.catalog.spark_catalog.io-impl", 
            "org.apache.iceberg.aws.s3.S3FileIO")\
    .config("spark.sql.catalog.spark_catalog.s3.endpoint", 
            "http://minio:9000")\
    .config("spark.sql.catalog.spark_catalog.s3.access-key-id", "admin")\
    .config("spark.sql.catalog.spark_catalog.s3.secret-access-key", "password")\
    .config("spark.sql.catalog.spark_catalog.s3.path-style-access", "true")\
    .getOrCreate()
```

---

## Interview Explanation

### "Tell me about your Spark-Iceberg pipeline"

**Answer Structure:**

1. **Business Problem:**
   > "We needed to ingest data from 3 different sources (S3, Kafka, Shopify API) into a unified analytics platform with ACID guarantees and schema evolution support."

2. **Architecture:**
   > "I built a Lambda-style architecture using Spark for processing and Iceberg as the table format. Data flows from sources through Spark transformations into Iceberg tables stored in MinIO (S3-compatible), with metadata managed by Iceberg REST Catalog."

3. **Why Iceberg:**
   > "Iceberg provides:
   > - **Schema evolution** - Shopify API returns nested JSON that changes frequently
   > - **Time travel** - Business can query historical snapshots
   > - **ACID transactions** - Multiple pipelines write concurrently
   > - **Partition hiding** - Queries only scan relevant data"

4. **Challenges Solved:**
   > - "S3A filesystem missing → Added Hadoop AWS JARs to Spark image"
   > - "Schema mismatches → Used Iceberg's schema evolution with `createOrReplace()`"
   > - "REST catalog caching → Implemented proper volume cleanup on restart"
   > - "Shopify pagination → Migrated from page-based to cursor-based pagination"

5. **Results:**
   > - "1,000 supplier records from S3"
   > - "50 streaming events from Kafka"
   > - "105 products from Shopify API"
   > - "255 transformed analytics records"
   > - "Full data lineage with snapshot history"

6. **Query Example:**
   ```sql
   -- Time travel to see yesterday's data
   SELECT product_id, SUM(action_count) 
   FROM spark_catalog.analytics.unified_analytics 
   TIMESTAMP AS OF CURRENT_DATE - 1
   GROUP BY product_id;
   ```

---

## Quick Reference Commands

```bash
# Start everything
docker-compose up -d

# Check logs
docker-compose logs -f spark-iceberg
docker-compose logs -f rest
docker-compose logs -f minio

# Run pipelines
docker exec -it spark-iceberg python3 /home/iceberg/scripts/ingest_s3_supplier.py
docker exec -it spark-iceberg python3 /home/iceberg/scripts/ingest_kafka_events.py
docker exec -it spark-iceberg python3 /home/iceberg/scripts/ingest_shopify_products.py
docker exec -it spark-iceberg python3 /home/iceberg/scripts/transform_unified_view.py

# Query data
docker exec -it spark-iceberg python3 << 'EOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName('Query').master('spark://spark-iceberg:7077')\
    .config('spark.sql.catalog.spark_catalog', 'org.apache.iceberg.spark.SparkCatalog')\
    .config('spark.sql.catalog.spark_catalog.type', 'rest')\
    .config('spark.sql.catalog.spark_catalog.uri', 'http://rest:8181')\
    .config('spark.sql.catalog.spark_catalog.warehouse', 's3://warehouse/')\
    .config('spark.sql.catalog.spark_catalog.io-impl', 'org.apache.iceberg.aws.s3.S3FileIO')\
    .config('spark.sql.catalog.spark_catalog.s3.endpoint', 'http://minio:9000')\
    .config('spark.sql.catalog.spark_catalog.s3.access-key-id', 'admin')\
    .config('spark.sql.catalog.spark_catalog.s3.secret-access-key', 'password')\
    .config('spark.sql.catalog.spark_catalog.s3.path-style-access', 'true')\
    .getOrCreate()
spark.sql('SELECT COUNT(*) FROM spark_catalog.analytics.unified_analytics').show()
spark.stop()
EOF

# Stop everything
docker-compose down -v
```

---

## Summary

You built a **production-ready data lakehouse** with:
- ✅ Multi-source ingestion (Batch + Streaming + API)
- ✅ Schema evolution support
- ✅ ACID transactions
- ✅ Time travel queries
- ✅ Unified analytics views
- ✅ Complete data lineage

This is the same architecture used by companies like Netflix, Apple, and LinkedIn for their data platforms.
