import json
import os
import urllib.parse
from decimal import Decimal
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ["TABLE_NAME"]
TRUSTED_BUCKET = os.environ["TRUSTED_BUCKET"]

table = dynamodb.Table(TABLE_NAME)


def _decimalize(value):
    if isinstance(value, float):
        return Decimal(str(value))
    if isinstance(value, int):
        return Decimal(value)
    if isinstance(value, dict):
        return {k: _decimalize(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_decimalize(v) for v in value]
    return value


def lambda_handler(event, context):
    processed = []

    for record in event.get("Records", []):
        raw_bucket = record["s3"]["bucket"]["name"]
        raw_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        response = s3.get_object(Bucket=raw_bucket, Key=raw_key)
        body = response["Body"].read().decode("utf-8")
        order = json.loads(body)

        order_id = order.get("order_id") or order.get("orderId")
        if not order_id:
            raise ValueError("El JSON debe incluir order_id u orderId")

        item = {
            "order_id": str(order_id),
            "timestamp": str(order.get("timestamp", datetime.now(timezone.utc).isoformat())),
            "ciudad_zona": str(order.get("ciudad_zona", order.get("ciudad/zona", ""))),
            "estado_pedido": str(order.get("estado_pedido", order.get("estado del pedido", ""))),
            "monto": _decimalize(order.get("monto", 0)),
            "tiempo_entrega": _decimalize(order.get("tiempo_entrega", order.get("tiempo de entrega", 0))),
            "raw_bucket": raw_bucket,
            "raw_key": raw_key,
            "processed_at": datetime.now(timezone.utc).isoformat()
        }

        table.put_item(Item=item)

        trusted_key = raw_key.replace("orders/", "orders/trusted/", 1)
        s3.put_object(
            Bucket=TRUSTED_BUCKET,
            Key=trusted_key,
            Body=json.dumps(order, ensure_ascii=False).encode("utf-8"),
            ContentType="application/json",
            ServerSideEncryption="AES256",
            Metadata={
                "order_id": str(order_id),
                "processed_by": "lambda"
            }
        )

        processed.append({
            "order_id": str(order_id),
            "trusted_key": trusted_key
        })

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": processed})
    }
