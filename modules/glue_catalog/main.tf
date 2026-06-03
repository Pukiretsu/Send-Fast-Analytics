# ---------------------------------------------------------
# 🧬 Glue Database
# ---------------------------------------------------------
resource "aws_glue_catalog_database" "this" {
  name        = var.database_name
  description = var.database_description
}

# ---------------------------------------------------------
# 📋 Glue Table para Parquet
# ---------------------------------------------------------
resource "aws_glue_catalog_table" "this" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.this.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification        = "parquet"
    "projection.enabled"  = "false"
    "EXTERNAL"            = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = var.table_location
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "${var.table_name}-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "orderId"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }

    columns {
      name = "ciudad_zona"
      type = "string"
    }

    columns {
      name = "estado_pedido"
      type = "string"
    }

    columns {
      name = "monto"
      type = "double"
    }

    columns {
      name = "tiempo_entrega"
      type = "double"
    }

    columns {
      name = "metodo_pago"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}