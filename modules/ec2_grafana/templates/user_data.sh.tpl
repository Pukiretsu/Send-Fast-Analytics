#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/sendfast-grafana-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] Updating packages and installing runtime dependencies"
dnf update -y
dnf install -y docker jq awscli

systemctl enable docker
systemctl start docker

mkdir -p /opt/grafana/provisioning/datasources
mkdir -p /opt/grafana/data

# Las credenciales iniciales de Grafana no se escriben en Terraform ni en el repositorio.
# La instancia las obtiene en tiempo de arranque desde AWS Secrets Manager usando su Instance Profile.
echo "[INFO] Reading Grafana admin secret from AWS Secrets Manager"
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id '${grafana_admin_secret_arn}' \
  --region '${aws_region}' \
  --query SecretString \
  --output text)

GRAFANA_ADMIN_USER=$(echo "$SECRET_JSON" | jq -r '.username')
GRAFANA_ADMIN_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

if [ -z "$GRAFANA_ADMIN_USER" ] || [ "$GRAFANA_ADMIN_USER" = "null" ]; then
  echo "[ERROR] Secret must contain a non-empty username field"
  exit 1
fi

if [ -z "$GRAFANA_ADMIN_PASSWORD" ] || [ "$GRAFANA_ADMIN_PASSWORD" = "null" ]; then
  echo "[ERROR] Secret must contain a non-empty password field"
  exit 1
fi

cat > /opt/grafana/provisioning/datasources/athena.yaml <<EOF_DS
apiVersion: 1

datasources:
  - name: AWS Athena
    type: grafana-athena-datasource
    access: proxy
    editable: true
    jsonData:
      authType: default
      defaultRegion: ${aws_region}
      catalog: AwsDataCatalog
      database: ${glue_database_name}
      workgroup: ${athena_workgroup_name}
      outputLocation: s3://${athena_bucket_name}/
EOF_DS

chown -R 472:472 /opt/grafana
chmod -R 775 /opt/grafana

docker rm -f grafana || true

echo "[INFO] Starting Grafana container"
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER="$GRAFANA_ADMIN_USER" \
  -e GF_SECURITY_ADMIN_PASSWORD="$GRAFANA_ADMIN_PASSWORD" \
  -e GF_INSTALL_PLUGINS='grafana-athena-datasource' \
  -e AWS_REGION='${aws_region}' \
  -v /opt/grafana/provisioning:/etc/grafana/provisioning \
  -v /opt/grafana/data:/var/lib/grafana \
  grafana/grafana:latest

echo "[INFO] Grafana bootstrap completed"
