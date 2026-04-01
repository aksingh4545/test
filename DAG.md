# 📝 Airflow DAG Code Explanation - iceberg_data_pipeline.py

## 🎯 What is This File?

This file (`dags/iceberg_data_pipeline.py`) is the **brain** of your entire data pipeline. It tells Airflow:
- **WHAT** tasks to run
- **WHEN** to run them
- **IN WHAT ORDER** they should execute

---

## 📂 Complete File Structure

```python
# 1. IMPORTS - Bringing in tools we need
# 2. LOGGING SETUP - For printing messages
# 3. DEFAULT ARGS - Common settings for all tasks
# 4. DAG DEFINITION - Main workflow configuration
# 5. TASK FUNCTIONS - Code that does the actual work
# 6. TASK DEFINITIONS - Creating task objects
# 7. DEPENDENCIES - Setting the order of execution
```

---

## 🔍 Line-by-Line Explanation

### Part 1: Imports (Lines 1-15)

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from datetime import datetime, timedelta
import logging
import os
import boto3
from botocore.client import Config as BotoConfig
```

**What each import does:**

| Import | Purpose | Simple Explanation |
|--------|---------|-------------------|
| `DAG` | Creates workflow | Like creating a new project plan |
| `PythonOperator` | Runs Python code | Executes Python functions as tasks |
| `BashOperator` | Runs shell commands | Executes terminal commands as tasks |
| `EmptyOperator` | Does nothing | Used for start/end markers |
| `datetime, timedelta` | Time handling | For dates and time durations |
| `logging` | Print messages | For showing info/error messages |
| `os` | Operating system | To check if files exist |
| `boto3` | AWS/MinIO client | To upload files to S3 storage |

---

### Part 2: Logging Setup (Lines 17-19)

```python
logging.basicConfig(
    level=logging.INFO, 
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)
```

**What this does:**
- Sets up a "printer" that shows messages with timestamps
- `INFO` level = Show normal messages (not debug, not just errors)
- Format = `2024-04-01 10:30:00 - INFO - Task started`

**Example output:**
```
2026-04-01 11:00:42 - INFO - Starting supplier data upload to MinIO...
2026-04-01 11:00:43 - INFO - Upload complete!
```

---

### Part 3: Default Arguments (Lines 21-26)

```python
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}
```

**What each setting means:**

| Setting | Value | Meaning |
|---------|-------|---------|
| `owner` | 'airflow' | Who owns this DAG (shows in UI) |
| `depends_on_past` | False | Don't wait for previous runs |
| `retries` | 1 | If task fails, try 1 more time |
| `retry_delay` | 2 minutes | Wait 2 min before retrying |

**Simple explanation:** If a task fails, Airflow will automatically retry it once after waiting 2 minutes.

---

### Part 4: DAG Definition (Lines 28-38)

```python
dag = DAG(
    'iceberg_data_pipeline',
    default_args=default_args,
    description='Spark-Iceberg data pipeline',
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['iceberg', 'spark'],
)
```

**What each parameter does:**

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `'iceberg_data_pipeline'` | - | Unique name for this workflow |
| `default_args` | (dict above) | Uses the settings we defined |
| `description` | 'Spark-Iceberg...' | Shows in Airflow UI |
| `schedule_interval` | '@daily' | Run once per day automatically |
| `start_date` | Jan 1, 2024 | Don't run before this date |
| `catchup` | False | Don't run missed past executions |
| `tags` | ['iceberg', 'spark'] | For filtering in UI |

**Visual in Airflow UI:**
```
┌────────────────────────────────────────┐
│ DAG: iceberg_data_pipeline             │
│ Description: Spark-Iceberg data pipeline│
│ Schedule: @daily                       │
│ Tags: iceberg, spark                   │
└────────────────────────────────────────┘
```

---

### Part 5: Task Functions

#### Function 1: upload_supplier_data (Lines 43-68)

```python
def upload_supplier_data():
    """Upload CSV to MinIO."""
    logger.info("Starting supplier data upload to MinIO...")
    
    s3 = boto3.client('s3',
        endpoint_url='http://minio:9000',
        aws_access_key_id='admin',
        aws_secret_access_key='password',
        config=BotoConfig(signature_version='s3v4'))

    csv_file = '/opt/airflow/scripts/supplier_data_s3_updated.csv'
    
    if not os.path.exists(csv_file):
        logger.error(f"CSV file not found: {csv_file}")
        raise FileNotFoundError(f"CSV file not found: {csv_file}")

    try:
        s3.head_bucket(Bucket='supplier-info-data')
        logger.info("Bucket 'supplier-info-data' exists")
    except Exception as e:
        logger.warning(f"Bucket not found, creating: {e}")
        s3.create_bucket(Bucket='supplier-info-data')

    with open(csv_file, 'rb') as f:
        s3.upload_fileobj(f, 'supplier-info-data', 'supplier_data_s3/supplier_data_s3_updated.csv')
    
    logger.info("Upload complete! File: supplier_data_s3/supplier_data_s3_updated.csv")
```

**What this function does (step-by-step):**

```
Step 1: Connect to MinIO (S3 storage)
  ├─ Address: http://minio:9000
  ├─ Username: admin
  └─ Password: password

Step 2: Check if CSV file exists
  ├─ Location: /opt/airflow/scripts/supplier_data_s3_updated.csv
  └─ If missing → Raise error and stop

Step 3: Check if bucket exists
  ├─ Bucket name: supplier-info-data
  ├─ If exists → Great!
  └─ If not → Create it

Step 4: Upload the file
  ├─ Read CSV file
  ├─ Upload to: s3://supplier-info-data/supplier_data_s3/...
  └─ Log success message
```

**Real-world analogy:** Like uploading a file from your computer to Google Drive

---

#### Function 2: produce_kafka_events_task (Lines 71-99)

```python
def produce_kafka_events_task():
    """Produce test events to Kafka using script inside Spark container."""
    import subprocess
    
    logger.info("Producing Kafka events...")
    
    try:
        cmd = [
            'docker', 'exec', 'spark-iceberg', 
            'python3', '/home/iceberg/scripts/produce_kafka_events.py',
            '--count', '50',
            '--servers', 'kafka:29092',
            '--topic', 'user-behavior-events',
            '--delay', '0.05'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode != 0:
            logger.error(f"Kafka producer failed: {result.stderr}")
            raise Exception(f"Kafka producer failed: {result.stderr}")
        
        logger.info(f"Kafka producer output: {result.stdout}")
        logger.info("Kafka events produced successfully!")
        
    except subprocess.TimeoutExpired:
        logger.error("Kafka producer timed out")
        raise
    except Exception as e:
        logger.error(f"Error producing Kafka events: {e}")
        raise
```

**What this function does:**

```
Step 1: Build the command
  └─ docker exec spark-iceberg python3 produce_kafka_events.py
     ├─ --count 50           (create 50 events)
     ├─ --servers kafka:29092 (connect to Kafka)
     ├─ --topic user-behavior-events (send to this topic)
     └─ --delay 0.05         (wait 0.05s between events)

Step 2: Run the command
  └─ Execute inside spark-iceberg container

Step 3: Check result
  ├─ If returncode != 0 → Failed (show error)
  ├─ If returncode == 0 → Success (show output)
  └─ If timeout (>120s) → Raise timeout error
```

**What events are created:**
```json
{
  "user_id": "user_12345",
  "product_id": 1001,
  "category_id": 50,
  "action": "view",        // or "click", "cart", "buy", "search"
  "timestamp": "2024-01-15 10:30:00.123456"
}
```

**Why we use `docker exec`:** Airflow container needs to tell Spark container to run the script

---

### Part 6: Task Definitions

#### Task 1: Start Marker (Line 102)

```python
start = EmptyOperator(task_id='start', dag=dag)
```

**Purpose:** Just a visual marker in Airflow UI showing where the pipeline begins

**Visual:**
```
[start] → [other tasks...]
```

---

#### Task 2: Upload Supplier Data (Lines 105-109)

```python
upload = PythonOperator(
    task_id='upload_supplier_data',
    python_callable=upload_supplier_data,
    dag=dag
)
```

**What this creates:**
- A task box in Airflow UI
- Runs the `upload_supplier_data()` function
- Shows as "upload_supplier_data" in the workflow

---

#### Task 3: Produce Kafka Events (Lines 112-116)

```python
produce = PythonOperator(
    task_id='produce_kafka_events',
    python_callable=produce_kafka_events_task,
    dag=dag
)
```

**What this creates:**
- Runs the `produce_kafka_events_task()` function
- Creates 50 fake user behavior events in Kafka

---

#### Task 4: Ingest S3 Supplier Data (Lines 119-123)

```python
ingest_s3 = BashOperator(
    task_id='ingest_s3_supplier',
    bash_command='docker exec spark-iceberg spark-submit /home/iceberg/scripts/ingest_s3_supplier.py',
    dag=dag
)
```

**What this does:**
- Runs a **bash command** (not Python function)
- Command: `docker exec spark-iceberg spark-submit ...`
- Tells Spark container to run the supplier ingestion script

**What the script does:**
```
1. Read CSV from MinIO: s3://supplier-info-data/supplier_data_s3/...
2. Parse CSV into Spark DataFrame
3. Write to Iceberg table: analytics.suppliers
4. Result: 1000 supplier records in database
```

---

#### Task 5: Ingest Kafka Events (Lines 126-130)

```python
ingest_kafka = BashOperator(
    task_id='ingest_kafka_events',
    bash_command='docker exec spark-iceberg spark-submit /home/iceberg/scripts/ingest_kafka_events.py',
    dag=dag
)
```

**What this does:**
- Runs Kafka ingestion script in Spark container
- Reads events from Kafka topic
- Writes to Iceberg table: analytics.user_events

**Script flow:**
```
1. Connect to Kafka: kafka:29092
2. Read up to 1000 events from topic: user-behavior-events
3. Parse JSON events
4. Add processed_at timestamp
5. Write to Iceberg table
```

---

#### Task 6: Ingest Shopify Products (Lines 133-137)

```python
ingest_shopify = BashOperator(
    task_id='ingest_shopify_products',
    bash_command='docker exec spark-iceberg spark-submit /home/iceberg/scripts/ingest_shopify_products.py',
    dag=dag
)
```

**What this does:**
- Runs Shopify ingestion script
- Fetches products from Mock Shopify API
- Writes to Iceberg table: analytics.products

**API flow:**
```
1. Call: http://mock-shopify:5000/admin/api/2024-01/products.json
2. Get 500 products in JSON format
3. Parse complex nested JSON (variants, options, images)
4. Write to Iceberg table
```

---

#### Task 7: Transform Data (Lines 140-144)

```python
transform = BashOperator(
    task_id='transform_unified_view',
    bash_command='docker exec spark-iceberg spark-submit /home/iceberg/scripts/transform_unified_view.py',
    dag=dag
)
```

**What this does:**
- Runs transformation script
- Combines data from all 3 source tables
- Creates unified analytics report

**Transformation logic:**
```
Input Tables:
├─ suppliers (1000 rows)
├─ user_events (110 rows)
└─ products (500 rows)

Processing:
1. Join user_events with products (on product_id)
2. Aggregate by product and action type
3. Calculate metrics (total views, clicks, buys)
4. Add supplier information

Output Table:
└─ unified_analytics (combined report)
```

---

#### Task 8: Verify Data (Lines 147-151)

```python
verify = BashOperator(
    task_id='verify_data',
    bash_command='docker exec spark-iceberg spark-sql -e "USE analytics; SELECT COUNT(*) as supplier_count FROM suppliers"',
    dag=dag
)
```

**What this does:**
- Runs a SQL query to verify data was loaded
- Counts rows in suppliers table
- Shows result in Airflow logs

**Expected output:**
```
supplier_count
1000
```

---

#### Task 9: End Marker (Line 154)

```python
end = EmptyOperator(task_id='end', dag=dag)
```

**Purpose:** Visual marker showing where the pipeline ends

---

### Part 7: Dependencies (Lines 157-166)

```python
# Define task dependencies
# Main pipeline: Start -> Upload -> Ingest S3 -> Transform -> Verify -> End
start >> upload >> ingest_s3 >> transform >> verify >> end

# Kafka branch: Start -> Produce -> Ingest Kafka -> Transform
start >> produce >> ingest_kafka >> transform

# Shopify branch: Start -> Ingest Shopify -> Transform
start >> ingest_shopify >> transform
```

**What this creates (Visual Workflow):**

```
                                    ┌──────────────┐
                                    │   produce    │
                                    │      │       │
                                    │      ▼       │
┌──────┐   ┌────────┐   ┌──────────┐ │ ┌──────────┴──────────┐
│start │ → │ upload │ → │ingest_s3 │ → │      transform      │ → ┌─────┐
└──────┘   └────────┘   └──────────┘ │ └──────────┬──────────┘   │verify│
                                    │              │              └──┬──┘
                                    │ ┌──────────┬─┘                 │
                                    │ │ingest_   │                  │
                                    │ │shopify   │                  │
                                    │ └──────────┘                  │
                                    └────────────────────────────────┘
                                                              │
                                                              ▼
                                                           ┌─────┐
                                                           │ end │
                                                           └─────┘
```

**Explanation of `>>` operator:**
- `A >> B` means "A must finish before B starts"
- Creates an arrow from A to B in the workflow diagram

**Three parallel branches:**
1. **S3 Branch:** upload → ingest_s3 → transform
2. **Kafka Branch:** produce → ingest_kafka → transform
3. **Shopify Branch:** ingest_shopify → transform

All three branches meet at `transform` task (which waits for all to complete)

---

## 🎯 Complete Workflow Execution

### When you trigger the DAG:

```
Time 0:00 - Start
    ↓
Time 0:01 - upload_supplier_data (Python function)
    ├─ Connect to MinIO
    ├─ Check bucket exists
    └─ Upload CSV file
    ↓
Time 0:02 - [PARALLEL EXECUTION]
    ├─ ingest_s3_supplier (Bash command)
    ├─ produce_kafka_events (Python function)
    └─ ingest_shopify_products (Bash command)
    ↓
Time 0:05 - ingest_kafka_events (after produce completes)
    ↓
Time 0:10 - transform_unified_view (waits for all 3 ingestions)
    ├─ Read suppliers table
    ├─ Read user_events table
    ├─ Read products table
    └─ Create unified_analytics
    ↓
Time 0:12 - verify_data
    └─ Run SQL: SELECT COUNT(*) FROM suppliers
    ↓
Time 0:13 - End (Pipeline complete!)
```

---

## 🎨 What You See in Airflow UI

### Graph View:
```
┌─────────────────────────────────────────────────────────────────┐
│                    iceberg_data_pipeline                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [start]                                                         │
│     │                                                            │
│     ▼                                                            │
│  [upload_supplier_data]  ─────────┬──────────  [produce]        │
│     │                             │                │            │
│     ▼                             │                ▼            │
│  [ingest_s3_supplier]             │         [ingest_kafka]      │
│     │                             │                │            │
│     └──────────────┬──────────────┴────────────────┘            │
│                    │                                            │
│                    ▼                                            │
│           [ingest_shopify_products]                             │
│                    │                                            │
│                    ▼                                            │
│           [transform_unified_view]                              │
│                    │                                            │
│                    ▼                                            │
│              [verify_data]                                      │
│                    │                                            │
│                    ▼                                            │
│                  [end]                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Task Colors:
- 🟢 **Green** = Success
- 🔴 **Red** = Failed
- 🟡 **Yellow** = Running
- ⚪ **White** = Waiting
- 🔵 **Blue** = Queued

---

## 📊 Task Execution Details

### PythonOperator vs BashOperator

| Feature | PythonOperator | BashOperator |
|---------|---------------|--------------|
| **Runs** | Python function | Shell command |
| **Use case** | Complex logic | Simple commands |
| **Example** | `upload_supplier_data()` | `docker exec ...` |
| **Error handling** | Python exceptions | Exit codes |

### When to use which:

**Use PythonOperator when:**
- You need complex Python logic
- Need to handle exceptions
- Working with Python libraries (boto3, requests)

**Use BashOperator when:**
- Running external scripts
- Executing docker commands
- Running spark-submit

---

## 🔧 Key Code Patterns

### Pattern 1: Logging
```python
logger.info("Starting...")    # Normal message
logger.warning("Careful...")  # Warning (not critical)
logger.error("Failed!")       # Error message
```

### Pattern 2: Error Handling
```python
try:
    # Risky operation
    result = do_something()
except Exception as e:
    logger.error(f"Failed: {e}")
    raise  # Re-raise to mark task as failed
```

### Pattern 3: File Check
```python
if not os.path.exists(file_path):
    raise FileNotFoundError(f"Missing: {file_path}")
```

### Pattern 4: Subprocess
```python
result = subprocess.run(
    ['command', 'arg1', 'arg2'],
    capture_output=True,
    text=True,
    timeout=120
)

if result.returncode != 0:
    raise Exception(f"Failed: {result.stderr}")
```

---

## 🎓 Summary

### What This DAG Does:
1. **Orchestrates** 9 tasks in specific order
2. **Runs daily** automatically (schedule: @daily)
3. **Handles errors** with retries
4. **Processes data** from 3 sources (S3, Kafka, Shopify)
5. **Verifies** data was loaded correctly

### Key Concepts:
- **DAG** = Workflow definition
- **Operator** = Task type (Python, Bash, Empty)
- **Dependencies** = Task execution order (`>>`)
- **Task** = Individual unit of work
- **XCom** = Way tasks share data (not used here)

### Files Involved:
```
dags/iceberg_data_pipeline.py  ← This file (the workflow)
scripts/
├── upload_supplier_data.py    ← Called by PythonOperator
├── produce_kafka_events.py    ← Called by PythonOperator
├── ingest_s3_supplier.py      ← Called by spark-submit
├── ingest_kafka_events.py     ← Called by spark-submit
├── ingest_shopify_products.py ← Called by spark-submit
└── transform_unified_view.py  ← Called by spark-submit
```

---

## 🚀 Next Steps

To understand the full pipeline, read:
1. `BEGINNER_GUIDE.md` - Overall concepts
2. `scripts/ingest_s3_supplier.py` - How S3 ingestion works
3. `scripts/ingest_kafka_events.py` - How Kafka ingestion works
4. `scripts/ingest_shopify_products.py` - How Shopify API works
5. `scripts/transform_unified_view.py` - How data transformation works
