#!/bin/bash
set -e

dnf update -y
dnf install -y docker

systemctl enable docker
systemctl start docker

mkdir -p /opt/grafana/provisioning/datasources
mkdir -p /opt/grafana/data

cat > /opt/grafana/provisioning/datasources/athena.yaml <<EOF
apiVersion: 1

datasources:
  - name: AWS Athena
    type: grafana-athena-datasource
    access: proxy
    editable: true
    jsonData:
      authType: default
      defaultRegion: us-east-1
      catalog: AwsDataCatalog
      database: default
      workgroup: primary
      outputLocation: s3://serverless-datalake-dev-athena-results-233245302814/
EOF

chown -R 472:472 /opt/grafana
chmod -R 775 /opt/grafana

docker rm -f grafana || true

docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER='admin' \
  -e GF_SECURITY_ADMIN_PASSWORD='ChangeMe12345!' \
  -e GF_INSTALL_PLUGINS='grafana-athena-datasource' \
  -e AWS_REGION='us-east-1' \
  -v /opt/grafana/provisioning:/etc/grafana/provisioning \
  -v /opt/grafana/data:/var/lib/grafana \
  grafana/grafana:latest