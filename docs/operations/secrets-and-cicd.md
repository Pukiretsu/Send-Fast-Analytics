# Secretos y CI/CD

Esta guía resume cómo preparar los secretos para ejecutar el pipeline de GitHub Actions sin dejar credenciales dentro del repositorio.

## 1. Estado remoto de Terraform

Crea un bucket S3 para el estado y una tabla DynamoDB para locking antes del primer despliegue.

```bash
aws s3api create-bucket \
  --bucket sendfast-analytics-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket sendfast-analytics-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket sendfast-analytics-terraform-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 2. OIDC para GitHub Actions

El workflow espera asumir un rol de AWS con OIDC. El rol debe permitir, como mínimo, administrar los recursos de este proyecto y el backend remoto de Terraform.

Secret requerido:

```text
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/github-actions-sendfast
```

## 3. Secretos de aplicación

### Cognito

`TF_VAR_COGNITO_USERS` debe ser un JSON válido compatible con la variable `cognito_users`.

```json
{
  "admin": {
    "username": "admin_analytics",
    "email": "admin@example.com",
    "password": "ChangeThisPassword123!"
  }
}
```

### Grafana

GitHub Actions recibe estos dos secretos:

```text
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<password-seguro>
```

El pipeline crea o actualiza un secreto en AWS Secrets Manager con el nombre definido en la variable `GRAFANA_SECRET_NAME`. Terraform solo recibe el ARN del secreto y la instancia EC2 lee el valor durante el arranque.

## 4. Acceso seguro a Grafana

Por defecto Grafana no queda expuesto porque `allowed_grafana_cidr_blocks` es una lista vacía. Para habilitarlo desde una IP específica agrega este secret:

```json
TF_VAR_ALLOWED_GRAFANA_CIDR_BLOCKS=["190.1.2.3/32"]
```

Evita usar `0.0.0.0/0` salvo en demos temporales.

## 5. Variables públicas para la web

No se guardan manualmente. El job `terraform_deploy` exporta:

```text
api_ingesta_url
cognito_user_pool_id
cognito_client_id
webapp_bucket_name
cloudfront_distribution_id
```

Luego `web_build_deploy` genera `src/web/.env.production`, compila Vite y publica los archivos en S3.
