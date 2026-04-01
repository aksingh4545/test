Good — now I’ll give you a **clean, complete, no-confusion guide** of everything you just did.

This is your **working mental model + commands + explanations**.
Save this — this is your foundation.

---

# 🧠 1. COMPLETE ARCHITECTURE (FINAL UNDERSTANDING)

```text
Your Laptop
   ↓
Docker Network
   ├── Zookeeper
   ├── Kafka
   └── Airflow
          ↓
     runs producer.py
          ↓
        Kafka
          ↓
      Consumer (you)
```

---

# 🧠 2. ROLE OF EACH COMPONENT

| Component | Role                                     |
| --------- | ---------------------------------------- |
| Docker    | Runs everything in isolated environments |
| Kafka     | Message broker (stores data)             |
| Zookeeper | Manages Kafka                            |
| Airflow   | Scheduler (runs scripts)                 |
| Producer  | Sends data to Kafka                      |
| Consumer  | Reads data                               |

---

# 📦 3. FINAL WORKING docker-compose.yml

```yaml
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: zookeeper_prac
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka_prac
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  airflow:
    image: apache/airflow:2.9.1
    container_name: airflow_simple
    ports:
      - "8085:8080"
    volumes:
      - ./dags:/opt/airflow/dags
      - ./scripts:/opt/airflow/scripts
    environment:
      AIRFLOW__CORE__LOAD_EXAMPLES: "False"
    command: >
      bash -c "pip install kafka-python && airflow standalone"
```

---

# 🧠 IMPORTANT CONCEPTS (YOU MUST REMEMBER)

---

## 🔑 1. localhost vs container name

```text
localhost inside container ≠ your laptop
```

| Where you run code | Kafka address  |
| ------------------ | -------------- |
| Laptop             | localhost:9092 |
| Inside Docker      | kafka:9092     |

---

## 🔑 2. Volume mapping

```yaml
./scripts → /opt/airflow/scripts
```

👉 Means:

```text
Your file = visible inside container
```

---

## 🔑 3. bash_command meaning

```python
bash_command='python /opt/airflow/scripts/producer.py'
```

👉 Airflow runs:

```bash
python producer.py
```

inside container

---

## 🔑 4. Why pip failed

```text
pip → /root/bin/pip
```

👉 belongs to root
👉 airflow user can’t access → permission denied

---

## 🔑 5. Correct install pattern

❌ Wrong:

```text
Start container → install packages
```

✅ Correct:

```text
Install during startup (docker-compose)
```

---

# 🚀 4. STEP-BY-STEP COMMANDS (WORKING FLOW)

---

## 🔥 STEP 1 — CLEAN START

```bash
docker-compose down
docker-compose up -d
```

---

## 🔥 STEP 2 — CHECK CONTAINERS

```bash
docker ps
```

👉 You should see:

* kafka_prac
* zookeeper_prac
* airflow_simple

---

## 🔥 STEP 3 — WAIT FOR AIRFLOW

```bash
docker logs -f airflow_simple
```

👉 Wait until:

```text
Listening at: http://0.0.0.0:8080
```

---

## 🔥 STEP 4 — CREATE USER

```bash
docker exec -it airflow_simple airflow users create --username admin --firstname Akhil --lastname User --role Admin --email admin@example.com --password admin
```

---

## 🔥 STEP 5 — OPEN UI

```text
http://localhost:8085
```

Login:

```text
admin / admin
```

---

## 🔥 STEP 6 — CREATE KAFKA TOPIC

```bash
docker exec -it kafka_prac kafka-topics --create --topic test-topic --bootstrap-server kafka:9092 --partitions 1 --replication-factor 1
```

---

## 🔥 STEP 7 — START CONSUMER

```bash
docker exec -it kafka_prac kafka-console-consumer --bootstrap-server kafka:9092 --topic test-topic --from-beginning
```

---

## 🔥 STEP 8 — PRODUCER CODE (FINAL)

```python
from kafka import KafkaProducer
import json
import time

producer = KafkaProducer(
    bootstrap_servers="kafka:9092",
    value_serializer=lambda v: json.dumps(v).encode("utf-8")
)

for i in range(5):
    data = {"user": f"user_{i}", "action": "click"}
    producer.send("test-topic", value=data)
    print(f"Sent: {data}")
    time.sleep(1)

producer.flush()
```

---

## 🔥 STEP 9 — DAG CODE

```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

dag = DAG(
    'kafka_producer_dag',
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False
)

run_producer = BashOperator(
    task_id='run_producer',
    bash_command='python /opt/airflow/scripts/producer.py',
    dag=dag
)
```

---

## 🔥 STEP 10 — RUN DAG

1. Open Airflow UI
2. Enable DAG
3. Click **Trigger**

---

# 🎯 EXPECTED OUTPUT

Consumer should show:

```json
{"user": "user_0", "action": "click"}
{"user": "user_1", "action": "click"}
```

---

# 💥 COMMON ERRORS (AND WHY)

---

## ❌ NoBrokersAvailable

```text
Wrong host (localhost vs kafka)
```

---

## ❌ Permission denied

```text
Using wrong pip (root vs airflow user)
```

---

## ❌ ModuleNotFoundError

```text
Library not installed in container
```

---

## ❌ Airflow UI not loading

```text
Container not ready or webserver not started
```

---

# 🧠 FINAL MENTAL MODEL

```text
Docker = machines
Kafka = data pipe
Airflow = scheduler
Producer = sender
Consumer = receiver
```

---

# 🚀 WHAT YOU ACHIEVED

You built a **real data pipeline**:

```text
Airflow → Producer → Kafka → Consumer
```

---

# 👇 NEXT LEVEL (IMPORTANT)

Now you are ready for:

👉 Spark reading from Kafka
👉 Writing to Iceberg / Data Lake

---
