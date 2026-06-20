# SendFast Analytics Web

Aplicación React + Vite que simula el canal operativo de SendFast y envía pedidos al API Gateway protegido con Cognito JWT.

## Variables de entorno

La aplicación usa variables públicas de Vite. No son secretos, pero deben venir de la infraestructura desplegada.

```text
VITE_API_URL=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/ingesta
VITE_USER_POOL_ID=us-east-1_xxxxxxxxx
VITE_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
```

En CI/CD estas variables se generan automáticamente desde `terraform output -json`. Para desarrollo local puedes copiar `.env.example`:

```bash
cp .env.example .env.local
```

## Desarrollo local

```bash
npm install
npm run dev
```

## Validación y build

```bash
npm run lint
npm run build
```

El build final queda en `dist/` y el pipeline lo publica en el bucket S3 privado creado por Terraform.

## Modo mock

Si `VITE_USER_POOL_ID` o `VITE_CLIENT_ID` no están configuradas, la pantalla de login permite un modo mock local para facilitar pruebas visuales. En producción estas variables deben estar presentes.
