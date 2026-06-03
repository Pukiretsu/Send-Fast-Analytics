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
    raise TypeError(f"Type {type(obj)} not serializable")


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))

        now = datetime.datetime.now(datetime.timezone.utc)
        now_iso = now.isoformat()

        order_id = body.get("orderId") or f"ORD-{uuid.uuid4().hex[:12].upper()}"

        monto = Decimal(str(body.get("monto", 0)))
        tiempo_entrega = Decimal(str(body.get("tiempo_entrega", 15)))

        item = {
            "orderId": order_id,
            "timestamp": now_iso,
            "ciudad_zona": body.get("ciudad_zona", "Bogota-Centro"),
            "estado_pedido": body.get("estado_pedido", "ENTREGADO"),
            "monto": monto,
            "tiempo_entrega": tiempo_entrega,
            "metodo_pago": body.get("metodo_pago", "EFECTIVO"),
        }

        # 1. Guardar en DynamoDB
        table.put_item(Item=item)

        # 2. Guardar JSON crudo en S3 bucket de ingesta
        s3_key = (
            f"orders/raw/"
            f"year={now.year}/"
            f"month={now.month:02d}/"
            f"day={now.day:02d}/"
            f"hour={now.hour:02d}/"
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
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Pedido guardado con éxito",
                "orderId": order_id,
                "s3_key": s3_key
            }),
        }

    except Exception as e:
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "error": str(e)
            }),
        }