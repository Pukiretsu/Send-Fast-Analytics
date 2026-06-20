import os
import json
import datetime
from decimal import Decimal

import boto3
import pandas as pd
import awswrangler as wr


s3 = boto3.client("s3")

RAW_BUCKET = os.environ["RAW_BUCKET"]
STAGE_BUCKET = os.environ["STAGE_BUCKET"]

RAW_PREFIX = os.environ.get("RAW_PREFIX", "orders/raw/")
STAGE_PREFIX = os.environ.get("STAGE_PREFIX", "orders/parquet/")

LOOKBACK_MINUTES = int(os.environ.get("LOOKBACK_MINUTES", "15"))

GLUE_DATABASE = os.environ.get("GLUE_DATABASE", "sendfast_analytics_dev")
GLUE_TABLE = os.environ.get("GLUE_TABLE", "orders")


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError


def list_recent_json_objects(bucket, prefix, lookback_minutes):
    now = datetime.datetime.now(datetime.timezone.utc)
    cutoff_time = now - datetime.timedelta(minutes=lookback_minutes)

    recent_objects = []
    paginator = s3.get_paginator("list_objects_v2")

    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            last_modified = obj["LastModified"]

            if not key.endswith(".json"):
                continue

            if last_modified >= cutoff_time:
                recent_objects.append(key)

    return recent_objects


def read_json_from_s3(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8")
    return json.loads(content)


def lambda_handler(event, context):
    try:
        recent_keys = list_recent_json_objects(
            bucket=RAW_BUCKET,
            prefix=RAW_PREFIX,
            lookback_minutes=LOOKBACK_MINUTES,
        )

        # Safety net: si no hay registros nuevos, no procesa nada
        if not recent_keys:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "No hay registros nuevos para procesar",
                    "lookback_minutes": LOOKBACK_MINUTES,
                    "processed_files": 0,
                }),
            }

        records = []

        for key in recent_keys:
            record = read_json_from_s3(RAW_BUCKET, key)
            records.append(record)

        if not records:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "No se encontraron registros válidos",
                    "processed_files": 0,
                }),
            }

        df = pd.DataFrame(records)

        # Normalización de columnas esperadas
        expected_columns = [
            "orderId",
            "timestamp",
            "ciudad_zona",
            "estado_pedido",
            "monto",
            "tiempo_entrega",
            "metodo_pago",
        ]

        for column in expected_columns:
            if column not in df.columns:
                df[column] = None

        df = df[expected_columns]

        # Conversión de tipos
        df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce", utc=True)
        df["monto"] = pd.to_numeric(df["monto"], errors="coerce")
        df["tiempo_entrega"] = pd.to_numeric(df["tiempo_entrega"], errors="coerce")

        # Particiones para Athena
        df["year"] = df["timestamp"].dt.year.astype("Int64").astype(str)
        df["month"] = df["timestamp"].dt.month.astype("Int64").astype(str).str.zfill(2)
        df["day"] = df["timestamp"].dt.day.astype("Int64").astype(str).str.zfill(2)

        output_path = f"s3://{STAGE_BUCKET}/{STAGE_PREFIX}"

        wr.s3.to_parquet(
            df=df,
            path=output_path,
            dataset=True,
            mode="append",
            database=GLUE_DATABASE,
            table=GLUE_TABLE,
            partition_cols=["year", "month", "day"],
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "ETL ejecutado correctamente",
                "processed_files": len(recent_keys),
                "records": len(records),
                "output_path": output_path,
                "glue_database": GLUE_DATABASE,
                "glue_table": GLUE_TABLE,
            }),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            }),
        }
