
# Kafka + ZooKeeper Docker Setup — Debugging Guide

## 📌 Overview

This document explains the errors encountered while setting up Kafka with ZooKeeper using Docker Compose and how each issue was resolved.

---

# ❌ Errors Faced & ✅ Solutions

---

## 1. NodeExistsException

### 🔴 Error

```
KeeperException$NodeExistsException
```

### 💡 Cause

ZooKeeper already had a registered broker:

```
/brokers/ids/1
```

Kafka tried to register the same broker ID again → conflict.

### ✅ Solution

Remove stale ZooKeeper data:

```bash
docker-compose down -v
docker volume prune
docker-compose up
```

### 🧠 Key Learning

* ZooKeeper stores broker metadata persistently
* Restarting containers does NOT reset ZooKeeper state

---

## 2. Docker Networking Issue (localhost problem)

### 🔴 Error

```
Connection to localhost:9095 failed
```

### 💡 Cause

Inside Docker:

* `localhost` refers to the container itself
* Kafka couldn’t connect to itself using `localhost`

### ✅ Solution

Use service name instead:

```yaml
KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
```

### 🧠 Key Learning

* Containers communicate using service names, not localhost

---

## 3. YAML Indentation Error

### 🔴 Error

```
services.image must be a mapping
```

### 💡 Cause

Incorrect indentation in `docker-compose.yml`

### ❌ Wrong

```yaml
kafka:
image: confluentinc/cp-kafka:7.5.0
```

### ✅ Correct

```yaml
kafka:
  image: confluentinc/cp-kafka:7.5.0
```

### 🧠 Key Learning

* YAML is space-sensitive
* Always use proper indentation (2 spaces)

---

## 4. Multiple ZooKeeper Containers Conflict

### 🔴 Problem

Multiple ZooKeeper containers were running:

* `zookeeper`
* `zookeeper_prac`
* `airflow-zookeeper`

Kafka connected to the wrong one.

### ✅ Solution

Stop and remove all ZooKeeper containers:

```bash
docker stop zookeeper zookeeper_prac airflow-zookeeper
docker rm zookeeper zookeeper_prac airflow-zookeeper
```

### 🧠 Key Learning

* Kafka connects to container by name (`zookeeper:2181`)
* Multiple instances cause hidden conflicts

---

## 5. InconsistentClusterIdException

### 🔴 Error

```
InconsistentClusterIdException
```

### 💡 Cause

* ZooKeeper had a new cluster ID
* Kafka had old cluster data (`meta.properties`)

Mismatch → Kafka refused to start

### ✅ Solution

Reset both Kafka and ZooKeeper data:

```bash
docker-compose down -v
docker volume prune
docker-compose up
```

### 🧠 Key Learning

* Kafka and ZooKeeper must share the same cluster ID
* Partial reset causes mismatch errors

---

## 6. Temporary Connection Warning (Safe to Ignore)

### 🔴 Warning

```
Connection to kafka:9092 failed
```

### 💡 Cause

Kafka tried to connect to itself before fully starting

### ✅ Resolution

No action needed — Kafka retries and connects successfully

### ✔ Confirmation

```
[KafkaServer id=1] started
Controller connected to kafka:9092
```

---

# ✅ Final Working Configuration

```yaml
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: zookeeper_prac
    ports:
      - "2188:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka_prac
    depends_on:
      - zookeeper
    ports:
      - "9095:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181

      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT

      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
```

---

# 🚀 Final Outcome

| Component  | Status    |
| ---------- | --------- |
| ZooKeeper  | ✅ Running |
| Kafka      | ✅ Running |
| Networking | ✅ Fixed   |
| Cluster    | ✅ Healthy |

---

# 🧠 Key Takeaways

* Docker containers ≠ persistent data
* ZooKeeper holds critical Kafka metadata
* Always clean volumes when debugging Kafka
* Use service names for internal networking
* Avoid running multiple ZooKeeper instances

---

# 🔥 Next Steps

* Add Kafka producers/consumers
* Integrate with Airflow
* Migrate to **KRaft mode (no ZooKeeper)** for modern setups

---
