import io
from pendulum import datetime
from airflow.sdk import dag, task
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.databricks.operators.databricks import DatabricksRunNowOperator

BUCKET = "olist-raw-2026"
VOLUME = "/Volumes/olist/raw/landing"
BRONZE_JOB_ID = 420196258152683  # replace with your Job ID

DBT_BIN = "/usr/local/airflow/dbt_venv/bin/dbt"
DBT_DIR = "/usr/local/airflow/dbt"
DBT_PROFILES = "/usr/local/airflow/include/dbt_profiles"


@dag(
    start_date=datetime(2026, 9, 1),
    schedule=None,          # run manually for now
    catchup=False,
    params={"load_date": "2026-09-22"},
    tags=["olist"],
)
def olist_pipeline():

    @task
    def s3_to_volume(params=None):
        """Copy this load's CSVs from the S3 landing zone into the Databricks volume."""
        from airflow.providers.amazon.aws.hooks.s3 import S3Hook
        from databricks.sdk import WorkspaceClient

        load_date = params["load_date"]
        s3 = S3Hook(aws_conn_id="aws_default")
        workspace = WorkspaceClient()

        keys = [
            k for k in s3.list_keys(bucket_name=BUCKET, prefix="raw/olist/")
            if f"load_date={load_date}/" in k and k.endswith(".csv")
        ]
        if not keys:
            raise ValueError(f"No files found in S3 for load_date={load_date}")

        for key in keys:
            body = s3.get_key(key, BUCKET).get()["Body"].read()
            file_name = key.split("/")[-1]
            workspace.files.upload(
                f"{VOLUME}/load_date={load_date}/{file_name}",
                io.BytesIO(body),
                overwrite=True,
            )
        return len(keys)

    bronze_ingest = DatabricksRunNowOperator(
        task_id="bronze_ingest",
        databricks_conn_id="databricks_default",
        job_id=BRONZE_JOB_ID,
        job_parameters={"load_date": "{{ params.load_date }}"},
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT_BIN} build --project-dir {DBT_DIR} --profiles-dir {DBT_PROFILES}",
    )


    s3_to_volume() >> bronze_ingest >> dbt_build


olist_pipeline()