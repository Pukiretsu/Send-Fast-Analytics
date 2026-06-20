import os
import json
import uuid
import datetime
from decimal import Decimal

import boto3


dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

table_name = os.environ["DYNAMODB_TABLE"]
raw_bucket = os.environ["S3_RAW_BUCKET"]

table = dynamodb.Table(table_name)


def json_decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} is not JSON serializable")


def get_valid_timestamp(body):
    """
    Usa el timestamp enviado por el cliente si viene en el body.
    Si no viene, genera uno actual en UTC.
    """
    incoming_timestamp = body.get("timestamp")

    if incoming_timestamp and str(incoming_timestamp).strip():
        return str(incoming_timestamp)

    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def get_partition_from_timestamp(timestamp_value):
    """
    Genera particiones year/month/day/hour basadas en el timestamp del pedido.
    Si el timestamp no se puede parsear, usa la fecha actual.
    """
    try:
        cleaned_timestamp = timestamp_value.replace("Z", "+00:00")
        dt = datetime.datetime.fromisoformat(cleaned_timestamp)

        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=datetime.timezone.utc)

        return {
            "year": dt.year,
            "month": dt.month,
            "day": dt.day,
            "hour": dt.hour,
        }

    except Exception:
        now = datetime.datetime.now(datetime.timezone.utc)

        return {
            "year": now.year,
            "month": now.month,
            "day": now.day,
            "hour": now.hour,
        }


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))

        order_id = body.get("orderId") or f"ORD-{uuid.uuid4().hex[:12].upper()}"

        order_timestamp = get_valid_timestamp(body)
        partition = get_partition_from_timestamp(order_timestamp)

        monto = Decimal(str(body.get("monto", 0)))
        tiempo_entrega = Decimal(str(body.get("tiempo_entrega", 15)))

        item = {
            "orderId": order_id,
            "timestamp": order_timestamp,
            "ciudad_zona": body.get("ciudad_zona", "Bogota-Centro"),
            "estado_pedido": body.get("estado_pedido", "ENTREGADO"),
            "monto": monto,
            "tiempo_entrega": tiempo_entrega,
            "metodo_pago": body.get("metodo_pago", "EFECTIVO"),
        }

        # 1. Guardar en DynamoDB
        table.put_item(Item=item)

        # 2. Guardar JSON crudo en S3 usando partición basada en el timestamp del pedido
        s3_key = (
            f"orders/raw/"
            f"year={partition['year']}/"
            f"month={partition['month']:02d}/"
            f"day={partition['day']:02d}/"
            f"hour={partition['hour']:02d}/"
            f"{order_id}.json"
        )

        s3.put_object(
            Bucket=raw_bucket,
            Key=s3_key,
            Body=json.dumps(item, default=json_decimal_default),
            ContentType="application/json",
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
            },
            "body": json.dumps({
                "message": "Pedido guardado con éxito",
                "orderId": order_id,
                "timestamp": order_timestamp,
                "s3_key": s3_key,
            }),
        }

    except Exception as e:
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
            },
            "body": json.dumps({
                "error": str(e)
            }),
        }
