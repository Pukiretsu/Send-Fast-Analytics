# Recurso Base del Bucket S3
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.environment == "prod" ? false : true # Evita accidentes en producción

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# Control de Acceso Público (Public Access Block)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # Se amolda dinámicamente al booleano que le pases
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# 🔄 3. Versionado Automático (Recomendado para auditorías e ingesta)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Disabled"
  }
}

# 2. Recurso para vaciar el bucket antes de destruirlo
resource "null_resource" "remove_s3_objects" {
  depends_on = [aws_s3_bucket.this]

  # Este comando corre localmente en tu máquina para vaciar el bucket
  triggers = {
    bucket_name = aws_s3_bucket.this.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${self.triggers.bucket_name} --recursive"
  }
}

# 🌍 4. Configuración de Sitio Web Estático (Opcional mediante bloque dinámico)
resource "aws_s3_bucket_website_configuration" "this" {
  # Solo se crea este recurso si 'website_config' tiene datos (no es null)
  count  = var.website_config != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.website_config.index_document
  }

  dynamic "error_document" {
    for_each = var.website_config.error_document != null ? [var.website_config.error_document] : []
    content {
      key = error_document.value
    }
  }
}

resource "aws_s3_object" "files" {
  # Si upload_directory no es null, escanea la carpeta; si es null, el mapa queda vacío y no sube nada
  for_each = var.upload_directory != null ? fileset(var.upload_directory, "**/*") : toset([])

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${var.upload_directory}/${each.value}"

  # Mapeo de tipos de archivo para renderizado correcto en el navegador
  content_type = lookup(
    {
      "html" = "text/html",
      "css"  = "text/css",
      "js"   = "application/javascript",
      "png"  = "image/png",
      "jpg"  = "image/jpeg",
      "jpeg" = "image/jpeg",
      "svg"  = "image/svg+xml",
      "json" = "application/json"
    },
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )

  etag = filemd5("${var.upload_directory}/${each.value}")
}

# 📜 5. Política de Acceso Público para Lectura (Solo si block_public_access es false)
resource "aws_s3_bucket_policy" "public_read_policy" {
  # Solo creamos la política si el bucket está diseñado para ser público
  count  = var.block_public_access == false ? 1 : 0
  bucket = aws_s3_bucket.this.id

  # Documento de la política en formato JSON nativo de AWS
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*" # 🔓 Permitir a cualquier persona en internet
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*" # 👈 Aplica a todos los archivos dentro del bucket
      }
    ]
  })

  # 🔥 CRUCIAL: Terraform debe esperar a que el bloqueo de acceso público se rompa 
  # antes de intentar aplicar esta política, de lo contrario AWS la rechazará.
  depends_on = [aws_s3_bucket_public_access_block.this]
}