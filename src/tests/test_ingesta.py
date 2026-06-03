import boto3
import requests
import json
import random
import time

# Configuración (Reemplaza con tus valores de los outputs de Terraform)
API_URL = "https://yath7gmahf.execute-api.us-east-1.amazonaws.com/ingesta" 
USER_POOL_ID = "us-east-1_QTeE35X5R"
CLIENT_ID = "1enifbqofi52ijmp8d83ea9lhc"
USERNAME = "admin_analytics" # Usuario definido en tus variables.tf
PASSWORD = "AdminPasswordSecure2026!"  # Asegúrate de tener una contraseña temporal configurada

def get_jwt_token():
    client = boto3.client('cognito-idp', region_name='us-east-1')
    try:
        response = client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={'USERNAME': USERNAME, 'PASSWORD': PASSWORD}
        )
        return response['AuthenticationResult']['IdToken']
    except Exception as e:
        print(f"Error autenticando: {e}")
        return None

def send_orders(token, count=100):
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    ciudades = ["Bogota-Centro", "Medellin-Norte", "Cali-Sur"]
    
    for i in range(count):
        payload = {
            "orderId": f"TEST-{i}-{int(time.time())}",
            "ciudad_zona": random.choice(ciudades),
            "estado_pedido": "ENTREGADO",
            "monto": random.randint(10000, 50000),
            "tiempo_entrega": random.randint(10, 60)
        }
        
        resp = requests.post(API_URL, json=payload, headers=headers)
        if resp.status_code == 200:
            print(f"✅ Pedido {i+1} enviado.")
        else:
            print(f"❌ Error en {i+1}: {resp.status_code} - {resp.text}")
        time.sleep(0.5) # Pausa breve para no saturar

if __name__ == "__main__":
    token = get_jwt_token()
    if token:
        send_orders(token)