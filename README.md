# 🚚 Send Fast Analytics: Serverless Data Pipeline & BI
[![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-aws)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Language-Python-3776AB?logo=python)](https://www.python.org/)
[![License: GPL3](https://img.shields.io/badge/License-GPLv3-yellow.svg)](https://opensource.org/licenses/gpl-3.0)
[![Powered by Betek](https://img.shields.io/badge/Powered_by-BeTek-blueviolet?style=flat&logo=buffer)](https://betek.la/)

**Send Fast Analytics** es una plataforma de inteligencia de negocios diseñada para una startup de logística. El sistema resuelve la necesidad de transformar miles de eventos transaccionales (pedidos) en métricas estratégicas en tiempo real, utilizando una arquitectura **100% Serverless** de bajo costo y alta escalabilidad.

---

## Arquitectura
El proyecto implementa un flujo de datos desacoplado (Event-Driven) para asegurar que el análisis de datos no impacte la operación del negocio.

1.  **Ingesta:** Los pedidos se registran en **Amazon DynamoDB**.
2.  **Streaming:** Un trigger de **DynamoDB Streams** activa una función Lambda de procesamiento.
3.  **ETL & Almacenamiento:** La Lambda transforma el JSON crudo a formato **Parquet** y lo deposita en un Data Lake en **Amazon S3** particionado por fecha.
4.  **Análisis:** **Amazon Athena** consulta los archivos en S3 mediante SQL estándar.
5.  **Visualización:** Un dashboard en **Grafana** consume los datos de Athena para mostrar KPIs en tiempo real.

**TODO:** _Diagrama de arquitectura AWS_

---

## Decisiones Técnicas (ADR Highlights)

Aqui declaramos los highlights de las deciciones tecnicas que se tomen en el transcurso del proyecto

---

## Estructura del Proyecto
```text
/send-fast-analytics
├── .github/workflows/    # Automatización CI/CD
├── infra/                # Código de Terraform (IaC)
│   ├── modules/          # Recursos reutilizables
│   └── environments/dev/ # Configuración del entorno de desarrollo
├── src/                  # Código fuente (Lambdas en Python)
│   ├── ingesta/          # Registro de pedidos
│   └── etl/              # Procesamiento Dynamo -> S3
├── scripts/              # Simulador de generación de datos
└── docs/adr/             # Architecture Decision Records
```
## 🚀 Instalación y Despliegue

**Requisitos Previos**
- AWS CLI configurado con politicas y siguiendo el principio de minimo privilegio.
- Terraform v1.5.0+.
- Python 3.9+.

**Paso 1: Despliegue**
```bash
cd infra/environments/dev
terraform init
terraform apply
```

**Paso 2: Ejecutar Simulador de Datos**

Preferiblemente iniciar un entorno virtual de python ```venv```
```bash
cd scripts
pip install -r requirements.txt
python data_generator.py --orders 2000
```

## Metodología de Trabajo
Este proyecto fue desarrollado por un equipo de 4 personas utilizando **Kanban** en GitHub Projects. Priorizamos el flujo continuo, la documentación mínima viable y la revisión de código por pares (Peer Review) para asegurar la calidad del pipeline.

---
*Desarrollado como proyecto final para el bootcamp de cloud computing cohorte 2 - 2026*

[![Formación](https://img.shields.io/badge/Formación-BETEK%20|%20Cloud%20Computing-blueviolet?style=flat&logo=buffer)](https://betek.la/)
