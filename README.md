# Grafana Loki + Alloy Snippet

A flexible setup for shipping logs to Loki using Grafana Alloy.

This repository supports **two execution modes**:

* Run using **Docker Compose** (recommended for most environments)
* Run using **native Alloy binary** (optimized for low-resource environments, auto-managed via Makefile)

---

## Overview

This project uses:

* Grafana Alloy → log collection and processing
* Loki → log storage backend

Pipeline:

```text
logs → alloy (source → process → write) → loki
```

---

## Project Structure

```
.
├── alloy.hcl
├── docker-compose.yml
├── Makefile
├── .env.example
├── .env.example.sh
└── README.md
```

---

## ⚠️ Initial Setup (Required)

### Step 1 — Copy Environment File

#### if you using docker compose
```bash
cp .env.example .env
```

#### if you using native

```bash
cp .env.example.sh env.sh
```

### Step 2 — Modify Environment Values

```bash
LOG_LEVEL=debug

ENV=sit
HOST=192.168.162.XX

LOKI_URL=http://loki.url:withport/loki/api/v1/push
```

---

## Option 1 — Run with Docker

```bash
docker compose up -d
```

---

## Option 2 — Run with Native Alloy

```bash
make run
```

---

## Configuration

Main configuration:

```hcl
alloy.hcl
```

---

## Log Pipeline

```
file → parse (regex) → extract labels → add group/service → enrich (env, host) → send to loki
```

---

## Service Configuration (Team-Based)

Services are **explicitly defined** and owned by teams.

```hcl
local.file_match "services" {
  path_targets = [
    {
      __path__ = "/data/logs/service_name/service_name.log",
      group    = "group_name",
      service  = "service_name",
    },
  ]
}
```

---

### How to Add a New Service

Each team must register their service:

```hcl
{
  __path__ = "/data/logs/payment/payment.log",
  group    = "payments",
  service  = "payment",
}
```

---

## Labeling Strategy

### Static Labels

* `service` → service identifier
* `group` → team ownership

### Extracted Labels

* `level`
* `function`

### Global Labels

```hcl
env  = sys.env("ENV")
host = sys.env("HOST")
```

---

## Log Format Requirement

Expected format:

```
2026-01-01 10:00:00 INFO MyServiceImpl.doSomething - message here
```

---

## ⚠️ Team Ownership Model (Important)

This setup is designed around **team responsibility**, not automatic discovery.

### What This Means

* Each team is responsible for:

  * registering their service
  * maintaining correct `group` and `service` labels
* No automatic detection is performed
* Misconfiguration affects observability

---

## Naming Convention (Required)

To avoid inconsistency across teams, follow these rules:

### Service Name

* lowercase
* no spaces
* use hyphens if needed

Example:

```
payment-service
user-auth
```

---

### Group Name (Team Ownership)

* represents team or domain
* stable over time
* not environment-specific

Example:

```
payments
platform
auth
```

---

## Validation Guidelines

Before adding or modifying a service, ensure:

* Path exists and is readable
* Log format matches expected pattern
* `service` name is unique
* `group` is correct

---

### Recommended (Optional) Validation Script

You can add a simple validation step:

```bash
grep -E '__path__|group|service' alloy.hcl
```

Or build a script to:

* check duplicate services
* validate naming format
* verify file paths exist

---

## Common Issues

### Logs missing labels

Cause:

* log format does not match regex

---

### Wrong group assignment

Cause:

* incorrect manual entry

---

### Logs not appearing

Check:

* `LOKI_URL`
* `env.sh`
* Alloy logs (`alloy.log`)

---

## Notes

* Manual configuration is intentional
* Optimized for team ownership and clarity
* Not optimized for automatic scaling (by design)

---

## Future Improvements

* Config validation tooling
* Service registration automation
* Dynamic discovery (optional path)

---

## License

MIT
