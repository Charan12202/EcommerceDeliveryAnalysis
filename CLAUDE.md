# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Medallion-architecture analytics pipeline over the Brazilian Olist e-commerce dataset, focused on delivery performance. Data flows:

1. **Raw → S3**: `scripts/upload_to_s3.sh` (run from `data/raw/`) uploads CSVs to `s3://olist-raw-2026/raw/olist/<table>/load_date=<YYYY-MM-DD>/<file>.csv`. Table name is derived by stripping `olist_` and `_dataset.csv`.
2. **S3 → Databricks volume**: Airflow task `s3_to_volume` copies one `load_date` partition into `/Volumes/olist/raw/landing/load_date=<date>/`.
3. **Bronze**: an existing Databricks Job (`BRONZE_JOB_ID` in the DAG) ingests the volume into `olist.bronze.*`. The bronze job's code is **not** in this repo. Bronze tables carry an `_ingested_at` column.
4. **Silver / Gold**: dbt project in `olist_dbt/` builds `olist.silver.*` and `olist.gold.*` on Databricks SQL (Spark SQL dialect: `try_cast`, `qualify`, `datediff`, `max_by`, etc.).

## dbt (`olist_dbt/`)

Run from `olist_dbt/` with the local venv (`source venv/bin/activate` from repo root). Local profile lives in `~/.dbt/profiles.yml`; the Airflow copy is `airflow/include/dbt_profiles/profiles.yml` (needs `DATABRICKS_TOKEN` env var).

```bash
dbt build                              # run models + tests
dbt run --select silver                # one layer (folder)
dbt build --select fact_orders         # one model + its tests
dbt build --select +fact_orders        # model and all upstream
dbt test --select assert_fact_orders_volume   # a single test
```

Key conventions:
- **Silver** models dedupe bronze with `qualify row_number() over (partition by <pk> order by _ingested_at desc) = 1`, cast strings via `try_cast`, and normalize text (`lower(trim(...))`). Delivery metrics (`delivery_days`, `delay_days`, `is_late`) are derived in `silver_orders`.
- **Gold** is a star schema: `fact_orders` (one row per order), `fact_order_items`, and `dim_customer`/`dim_seller`/`dim_product`/`dim_date`. `dim_date` is generated in SQL (2016-01-01 → 2018-12-31); facts join it via integer `purchase_date_key` (`yyyyMMdd`).
- `macros/generate_schema_name.sql` overrides dbt's default so `+schema: silver` produces schema `silver` exactly (not `<target>_silver`).
- All data tests use `store_failures: true` and write failing rows to schema `dq_audit`.
- Tests: generic tests in `_schema.yml` per layer, a custom generic `non_negative` test (`tests/generic/`), and singular tests in `tests/` (e.g. `assert_fact_orders_volume` fails if `fact_orders` has < 90,000 rows).
- Sources are declared in `models/silver/_sources.yml` (`source('bronze', ...)`).

## Airflow (`airflow/`)

Astronomer (Astro CLI) project on Runtime 3.x (Airflow 3, `airflow.sdk` decorators). Single DAG: `dags/olist_pipeline.py` — `s3_to_volume >> bronze_ingest >> dbt_build`, manually triggered with param `load_date`.

```bash
cd airflow
astro dev start            # local Airflow in Docker
astro dev restart          # after changing requirements.txt / Dockerfile
astro dev pytest           # run tests in tests/
astro dev parse            # check DAGs import cleanly
```

- dbt runs inside the scheduler from a separate venv (`/usr/local/airflow/dbt_venv`, built in the `Dockerfile`) to avoid dependency conflicts with Airflow.
- `docker-compose.override.yml` mounts the **repo root** (`../`) at `/usr/local/airflow/dbt`, so the dbt project inside the container is at `/usr/local/airflow/dbt/olist_dbt`.
- Connections used: `aws_default` (S3), `databricks_default` (Databricks job). `WorkspaceClient()` in `s3_to_volume` reads Databricks auth from environment variables (`airflow/.env`).
- `tests/dags/test_dag_example.py` is the Astro template test: it requires every DAG to have tags and `default_args["retries"] >= 2`.

## Git workflow

Work happens on `feature/*` branches merged via PR (silver-layer → gold-layer → data-quality → airflow).
