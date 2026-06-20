import os
import json
import uuid
import time
import random
import datetime
from typing import Optional, Dict, Any

import boto3
import requests
from botocore.exceptions import ClientError


# ---------------------------------------------------------
# Configuración principal
# ---------------------------------------------------------
API_URL = os.getenv("API_URL", "")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
USER_POOL_ID = os.getenv("USER_POOL_ID", "")
CLIENT_ID = os.getenv("CLIENT_ID", "")

USERNAME = os.getenv("COGNITO_USERNAME", "")
PASSWORD = os.getenv("COGNITO_PASSWORD", "")

TOTAL_ORDERS = int(os.getenv("TOTAL_ORDERS", "4000"))
ORDERS_PER_BATCH = int(os.getenv("ORDERS_PER_BATCH", "20"))

# Para demo está entre 5 y 60 segundos.
# Para 1 a 5 minutos reales, usa:
# MIN_WAIT_SECONDS=60
# MAX_WAIT_SECONDS=300
MIN_WAIT_SECONDS = int(os.getenv("MIN_WAIT_SECONDS", "5"))
MAX_WAIT_SECONDS = int(os.getenv("MAX_WAIT_SECONDS", "60"))

REQUEST_TIMEOUT_SECONDS = int(os.getenv("REQUEST_TIMEOUT_SECONDS", "30"))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", "3"))

# Rango de timestamps mock
DAYS_BACK = int(os.getenv("DAYS_BACK", "7"))
START_HOUR = int(os.getenv("START_HOUR", "7"))
END_HOUR = int(os.getenv("END_HOUR", "22"))


# ---------------------------------------------------------
# Datos mock similares a la webapp
# ---------------------------------------------------------
CIUDADES_ZONAS = [
    "Bogota-Centro",
    "Bogota-Norte",
    "Bogota-Sur",
    "Bogota-Occidente",
    "Bogota-Chapinero",
    "Bogota-Usaquen",
    "Bogota-Suba",
    "Medellin-Norte",
    "Medellin-Sur",
    "Medellin-Poblado",
    "Medellin-Laureles",
    "Cali-Norte",
    "Cali-Sur",
    "Cali-Oeste",
    "Barranquilla-Norte",
    "Barranquilla-Centro",
    "Cartagena-Bocagrande",
    "Bucaramanga-Cabecera",
    "Pereira-Centro",
]

METODOS_PAGO = [
    "NEQUI",
    "PSE",
    "TARJETA_CREDITO",
    "TARJETA_DEBITO",
    "DAVIPLATA",
    "EFECTIVO",
    "BANCOLOMBIA_TRANSFERENCIA",
    "MERCADO_PAGO",
]

# Distribución ponderada de estados:
# - ENTREGADO: mayoría de pedidos exitosos
# - EN_CAMINO / EN_PREPARACION / PENDIENTE: pedidos vivos en operación
# - CANCELADO: menor proporción para que la tasa de cancelación sea visible, pero baja
ESTADOS_PEDIDO_PONDERADOS = [
    ("ENTREGADO", 78),
    ("EN_CAMINO", 8),
    ("EN_PREPARACION", 6),
    ("PENDIENTE", 4),
    ("CANCELADO", 4),
]

# Rangos realistas por estado
TIEMPO_ENTREGA_POR_ESTADO = {
    "ENTREGADO": (18, 55),
    "EN_CAMINO": (20, 60),
    "EN_PREPARACION": (10, 35),
    "PENDIENTE": (5, 20),
    "CANCELADO": (0, 15),
}

MONTO_POR_ESTADO = {
    "ENTREGADO": (12000, 180000),
    "EN_CAMINO": (12000, 160000),
    "EN_PREPARACION": (12000, 140000),
    "PENDIENTE": (12000, 120000),
    "CANCELADO": (8000, 90000),
}


# ---------------------------------------------------------
# Utilidades
# ---------------------------------------------------------
def random_timestamp_last_days() -> str:
    """
    Genera un timestamp aleatorio en los últimos DAYS_BACK días,
    entre START_HOUR y END_HOUR.

    Por defecto:
    - Últimos 15 días
    - Entre 7:00 AM y 10:00 PM
    """
    now = datetime.datetime.now(datetime.timezone.utc)

    days_ago = random.randint(0, DAYS_BACK - 1)
    selected_day = now - datetime.timedelta(days=days_ago)

    random_hour = random.randint(START_HOUR, END_HOUR)
    random_minute = random.randint(0, 59)
    random_second = random.randint(0, 59)

    random_datetime = selected_day.replace(
        hour=random_hour,
        minute=random_minute,
        second=random_second,
        microsecond=0
    )

    return random_datetime.isoformat()


def validate_required_environment() -> None:
    missing = [
        name for name, value in {
            "API_URL": API_URL,
            "USER_POOL_ID": USER_POOL_ID,
            "CLIENT_ID": CLIENT_ID,
            "COGNITO_USERNAME": USERNAME,
            "COGNITO_PASSWORD": PASSWORD,
        }.items()
        if not value
    ]

    if missing:
        raise RuntimeError(
            "Faltan variables de entorno requeridas para ejecutar la prueba de ingesta: "
            + ", ".join(missing)
        )


def get_jwt_token() -> Optional[str]:
    """
    Obtiene un IdToken desde Cognito usando USER_PASSWORD_AUTH.
    """
    validate_required_environment()
    client = boto3.client("cognito-idp", region_name=AWS_REGION)

    try:
        response = client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": USERNAME,
                "PASSWORD": PASSWORD,
            },
        )

        auth_result = response.get("AuthenticationResult")
        if not auth_result:
            print("❌ Cognito no retornó AuthenticationResult.")
            print(json.dumps(response, indent=2, default=str))
            return None

        return auth_result["IdToken"]

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code")
        error_message = e.response.get("Error", {}).get("Message")

        print(f"❌ Error autenticando en Cognito: {error_code} - {error_message}")

        if error_code == "NotAuthorizedException":
            print("   Revisa usuario, contraseña o si el usuario aún tiene contraseña temporal.")
        elif error_code == "UserNotConfirmedException":
            print("   El usuario existe, pero no está confirmado en Cognito.")
        elif error_code == "PasswordResetRequiredException":
            print("   El usuario requiere reset de contraseña.")

        return None

    except Exception as e:
        print(f"❌ Error inesperado autenticando: {e}")
        return None


def choose_weighted_status() -> str:
    """
    Selecciona un estado usando pesos.
    """
    statuses = [item[0] for item in ESTADOS_PEDIDO_PONDERADOS]
    weights = [item[1] for item in ESTADOS_PEDIDO_PONDERADOS]

    return random.choices(statuses, weights=weights, k=1)[0]


def generate_mock_order() -> Dict[str, Any]:
    """
    Genera el mismo payload que espera la Lambda de ingesta.
    """
    estado_pedido = choose_weighted_status()

    monto_min, monto_max = MONTO_POR_ESTADO[estado_pedido]
    tiempo_min, tiempo_max = TIEMPO_ENTREGA_POR_ESTADO[estado_pedido]

    monto = random.randint(monto_min, monto_max)
    tiempo_entrega = random.randint(tiempo_min, tiempo_max)

    return {
        "orderId": str(uuid.uuid4()),
        "timestamp": random_timestamp_last_days(),
        "ciudad_zona": random.choice(CIUDADES_ZONAS),
        "estado_pedido": estado_pedido,
        "monto": monto,
        "tiempo_entrega": tiempo_entrega,
        "metodo_pago": random.choice(METODOS_PAGO),
    }


def send_order(token: str, payload: Dict[str, Any]) -> requests.Response:
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    return requests.post(
        API_URL,
        json=payload,
        headers=headers,
        timeout=REQUEST_TIMEOUT_SECONDS,
    )


def send_order_with_retries(
    token: str,
    payload: Dict[str, Any]
) -> tuple[bool, Optional[str], Optional[int]]:
    """
    Envía una orden con reintentos simples.
    Retorna:
      success, response_text, status_code
    """
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = send_order(token, payload)

            if 200 <= response.status_code < 300:
                return True, response.text, response.status_code

            # Si es 401/403, probablemente token vencido o inválido.
            if response.status_code in [401, 403]:
                return False, response.text, response.status_code

            print(
                f"⚠️ Intento {attempt}/{MAX_RETRIES} falló "
                f"con status {response.status_code}: {response.text}"
            )

        except requests.exceptions.RequestException as e:
            print(f"⚠️ Intento {attempt}/{MAX_RETRIES} falló por error de red: {e}")

        if attempt < MAX_RETRIES:
            backoff = attempt * 5
            print(f"⏳ Reintentando en {backoff} segundos...")
            time.sleep(backoff)

    return False, None, None


# ---------------------------------------------------------
# Envío principal
# ---------------------------------------------------------
def send_orders_intermitently(total_orders: int = TOTAL_ORDERS) -> None:
    token = get_jwt_token()

    if not token:
        print("❌ No fue posible obtener JWT. Se detiene el proceso.")
        return

    sent = 0
    failed = 0

    status_counter = {
        "ENTREGADO": 0,
        "EN_CAMINO": 0,
        "EN_PREPARACION": 0,
        "PENDIENTE": 0,
        "CANCELADO": 0,
    }

    print("🚀 Iniciando envío intermitente de pedidos")
    print(f"API_URL: {API_URL}")
    print(f"Total objetivo: {total_orders}")
    print(f"Pedidos por lote: {ORDERS_PER_BATCH}")
    print(f"Espera entre lotes: {MIN_WAIT_SECONDS}s a {MAX_WAIT_SECONDS}s")
    print(f"Timestamps aleatorios: últimos {DAYS_BACK} días")
    print(f"Horario simulado: {START_HOUR}:00 a {END_HOUR}:59 UTC")
    print("Distribución esperada de estados:")
    for estado, peso in ESTADOS_PEDIDO_PONDERADOS:
        print(f"  - {estado}: {peso}% aprox.")
    print("---------------------------------------------------------")

    while sent < total_orders:
        current_batch_size = min(ORDERS_PER_BATCH, total_orders - sent)

        print(f"\n📦 Iniciando lote de {current_batch_size} pedidos")

        for _ in range(current_batch_size):
            order_number = sent + 1
            payload = generate_mock_order()
            estado = payload["estado_pedido"]

            print(f"\n📦 Enviando pedido {order_number}/{total_orders} - Estado: {estado}")
            print(json.dumps(payload, indent=2, ensure_ascii=False))

            success, response_text, status_code = send_order_with_retries(token, payload)

            # Si el token falló, intentar renovar una vez
            if not success and status_code in [401, 403]:
                print("🔐 Token inválido o expirado. Solicitando nuevo JWT...")
                token = get_jwt_token()

                if not token:
                    print("❌ No fue posible renovar JWT. Se detiene el proceso.")
                    break

                success, response_text, status_code = send_order_with_retries(token, payload)

            if success:
                sent += 1
                status_counter[estado] = status_counter.get(estado, 0) + 1

                print(f"✅ Pedido enviado correctamente. Progreso: {sent}/{total_orders}")
                print(f"📊 Estados enviados: {status_counter}")

                if response_text:
                    print(f"Respuesta API: {response_text}")
            else:
                failed += 1
                print(f"❌ Pedido fallido. Fallidos acumulados: {failed}")
                if response_text:
                    print(f"Respuesta API: {response_text}")

            if sent >= total_orders:
                break

        if sent < total_orders:
            wait_seconds = random.randint(MIN_WAIT_SECONDS, MAX_WAIT_SECONDS)
            wait_minutes = round(wait_seconds / 60, 2)
            print(
                f"\n⏳ Esperando {wait_seconds} segundos "
                f"({wait_minutes} min) antes del próximo lote..."
            )
            time.sleep(wait_seconds)

    print("\n---------------------------------------------------------")
    print("🏁 Proceso finalizado")
    print(f"✅ Pedidos enviados: {sent}")
    print(f"❌ Pedidos fallidos: {failed}")
    print("📊 Resumen por estado:")

    for estado, cantidad in status_counter.items():
        porcentaje = round((cantidad / sent) * 100, 2) if sent > 0 else 0
        print(f"  - {estado}: {cantidad} pedidos ({porcentaje}%)")

    print("---------------------------------------------------------")


if __name__ == "__main__":
    send_orders_intermitently()
