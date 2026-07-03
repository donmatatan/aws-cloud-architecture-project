#!/bin/bash
export AWS_PAGER=""

# =========================================================================
# UTILERÍAS DE VERIFICACIÓN
# =========================================================================
function verificar() {
  if [ $? -eq 0 ]; then
    echo -e "\e[32m✅ [ÉXITO] $1\e[0m"
  else
    echo -e "\e[31m❌ [ERROR] $1\e[0m"
    exit 1
  fi
}

echo "========================================================================="
# PARTE 1: ALMACENAMIENTO
echo "Ejecutando PARTE 1: ALMACENAMIENTO..."
# =========================================================================

# Crear el bucket S3 estándar (Archivos uso frecuente y backups recientes):
aws s3api create-bucket --bucket acme-datos-frecuentes --endpoint-url=http://localhost:4566
verificar "Creación de bucket acme-datos-frecuentes"

# Crear el bucket para archivado histórico y backups antiguos (S3 Glacier Flexible Retrieval):
aws s3api create-bucket --bucket acme-archivado-historico --endpoint-url=http://localhost:4566
verificar "Creación de bucket acme-archivado-historico"

# Aplicar política de ciclo de vida:
aws s3api put-bucket-lifecycle-configuration --bucket acme-datos-frecuentes --lifecycle-configuration file://lifecycle.json --endpoint-url=http://localhost:4566
verificar "Aplicar política de ciclo de vida en acme-datos-frecuentes"

# Verificación de la Parte 1
echo "Verificando recursos de la Parte 1..."
aws s3api head-bucket --bucket acme-datos-frecuentes --endpoint-url=http://localhost:4566 >/dev/null
verificar "Bucket acme-datos-frecuentes existe y es accesible"
aws s3api head-bucket --bucket acme-archivado-historico --endpoint-url=http://localhost:4566 >/dev/null
verificar "Bucket acme-archivado-historico existe y es accesible"


echo "========================================================================="
# PARTE 2: BASES DE DATOS RELACIONALES
echo "Ejecutando PARTE 2: BASES DE DATOS RELACIONALES..."
# =========================================================================

# Desplegar una instancia RDS con PostgreSQL (se considera backups y alta disponibilidad):
aws rds create-db-instance \
  --db-instance-identifier acme-postgres-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username jairoadmin \
  --master-user-password MiPasswordSeguro123 \
  --allocated-storage 20 \
  --backup-retention-period 7 \
  --multi-az \
  --endpoint-url=http://localhost:4566
verificar "Creación de la instancia RDS PostgreSQL"

# Verificación de la Parte 2
echo "Verificando recursos de la Parte 2..."
aws rds describe-db-instances --db-instance-identifier acme-postgres-db --endpoint-url=http://localhost:4566 >/dev/null
verificar "Instancia RDS PostgreSQL existe en Floci"


echo "========================================================================="
# PARTE 3: BASE DE DATOS NoSQL
echo "Ejecutando PARTE 3: BASE DE DATOS NoSQL..."
# =========================================================================

# Tabla que representa los tickets del depto de SOPORTE con 3 Índices Secundarios:
aws dynamodb create-table \
  --table-name AcmeTicketsSoporte \
  --attribute-definitions \
      AttributeName=TicketId,AttributeType=S \
      AttributeName=ClienteId,AttributeType=S \
      AttributeName=Estado,AttributeType=S \
      AttributeName=Prioridad,AttributeType=S \
  --key-schema \
      AttributeName=TicketId,KeyType=HASH \
  --provisioned-throughput \
      ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --global-secondary-indexes \
    "[
      {
        \"IndexName\": \"Index_Cliente\",
        \"KeySchema\": [{\"AttributeName\":\"ClienteId\",\"KeyType\":\"HASH\"}],
        \"Projection\": {\"ProjectionType\":\"ALL\"},
        \"ProvisionedThroughput\": {\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}
      },
      {
        \"IndexName\": \"Index_Estado\",
        \"KeySchema\": [{\"AttributeName\":\"Estado\",\"KeyType\":\"HASH\"}],
        \"Projection\": {\"ProjectionType\":\"ALL\"},
        \"ProvisionedThroughput\": {\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}
      },
      {
        \"IndexName\": \"Index_Prioridad\",
        \"KeySchema\": [{\"AttributeName\":\"Prioridad\",\"KeyType\":\"HASH\"}],
        \"Projection\": {\"ProjectionType\":\"ALL\"},
        \"ProvisionedThroughput\": {\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}
      }
    ]" \
  --endpoint-url=http://localhost:4566
verificar "Creación de la tabla DynamoDB AcmeTicketsSoporte"

# =========================================================================
# ESTRATEGIA DE RESPALDO (PITR) - MÉTRICA: Estrategia de respaldo NoSQL
# =========================================================================
# Habilitar Point-in-Time Recovery (PITR) para recuperación ante desastres de los últimos 35 días
aws dynamodb update-continuous-backups \
  --table-name AcmeTicketsSoporte \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --endpoint-url=http://localhost:4566
verificar "Habilitación de Backup Continuo (PITR) en DynamoDB"

# Verificación de que el backup continuo está activo en la tabla
aws dynamodb describe-continuous-backups --table-name AcmeTicketsSoporte --endpoint-url=http://localhost:4566 --query "ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus" --output text | grep -q "ENABLED"
verificar "Verificación de Backup Continuo (PITR) en estado ENABLED"

# Prueba de integración con una aplicación. 
# Usamos como aplicación AWS CLI para mostrar que se acaba de registrar un ticket:
aws dynamodb put-item \
  --table-name AcmeTicketsSoporte \
  --item '{
    "TicketId": {"S": "TK-1001"},
    "ClienteId": {"S": "CLIENTE-ACME-99"},
    "Estado": {"S": "Abierto"},
    "Prioridad": {"S": "Alta"},
    "FechaCreacion": {"S": "2026-07-02"},
    "Descripcion": {"S": "El servidor on-premise se quedo sin espacio en disco duro"}
  }' \
  --endpoint-url=http://localhost:4566
verificar "Inserción de registro de prueba (put-item) en DynamoDB"

# Comprobamos que se registró correctamente el ticket:
aws dynamodb query \
  --table-name AcmeTicketsSoporte \
  --index-name Index_Cliente \
  --key-condition-expression "ClienteId = :v1" \
  --expression-attribute-values '{":v1": {"S": "CLIENTE-ACME-99"}}' \
  --endpoint-url=http://localhost:4566
verificar "Consulta de verificación (query) en DynamoDB"

echo "========================================================================="
# PARTE 4: SERVICIOS DE CÓMPUTO
echo "Ejecutando PARTE 4: SERVICIOS DE CÓMPUTO..."
# =========================================================================

# Comprimimos el lambda_function.py
zip function.zip lambda_function.py
verificar "Compresión de lambda_function.py"

# Crea el Rol de Seguridad simulado (Requisito de AWS para Lambda) y obtiene su ARN:
ROLE_ARN=$(aws iam create-role \
  --role-name AcmeLambdaRole \
  --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Effect": "Allow","Principal": {"Service": "lambda.amazonaws.com"},"Action": "sts:AssumeRole"}]}' \
  --query 'Role.Arn' --output text \
  --endpoint-url=http://localhost:4566)
verificar "Creación del rol IAM AcmeLambdaRole"

# Despliegue de Lambda
aws lambda create-function \
  --function-name AcmeProcesarVentas \
  --runtime python3.9 \
  --zip-file fileb://function.zip \
  --handler lambda_function.lambda_handler \
  --role $ROLE_ARN \
  --endpoint-url=http://localhost:4566
verificar "Despliegue de la función Lambda AcmeProcesarVentas"

# Realizar Pruebas de Escalabilidad y Ejecución bajo Carga
echo "Ejecutando pruebas de escalabilidad sobre Lambda..."
for i in {1..10}; do 
  aws lambda invoke --function-name AcmeProcesarVentas --endpoint-url=http://localhost:4566 response_$i.json >/dev/null
  verificar "Invocación $i de Lambda"
done

# Verificación de la Parte 4
aws lambda get-function --function-name AcmeProcesarVentas --endpoint-url=http://localhost:4566 >/dev/null
verificar "La función Lambda existe y está disponible en Floci"


echo "========================================================================="
# PARTE 5: SERVICIOS DE RED EN LA NUBE
echo "Ejecutando PARTE 5: SERVICIOS DE RED EN LA NUBE..."
# =========================================================================

# Crear la VPC (Le asignamos un bloque de direcciones IP 10.0.0.0/16)
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de la VPC (10.0.0.0/16)"

# Crear la Subred Pública A (Bloque 10.0.1.0/24 en us-east-1a)
SUBNET_PUB_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de Subred Pública A"

# Crear la Subred Pública B (Bloque 10.0.3.0/24 en us-east-1b)
SUBNET_PUB_B_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de Subred Pública B"

# Crear la Subred Privada A (Bloque 10.0.2.0/24 en us-east-1a)
SUBNET_PRIV_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de Subred Privada A"

# 1. Crear el Grupo de Seguridad para el Balanceador de Carga (Público)
SG_ALB_ID=$(aws ec2 create-security-group --group-name acme-balanc-sg --description "Firewall para el Balanceador ALB" --vpc-id $VPC_ID --query 'GroupId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de Grupo de Seguridad para ALB"

# REGLA 1: Permitir entrada web estándar (Puerto 80 - HTTP) desde cualquier origen al balanceador
aws ec2 authorize-security-group-ingress --group-id $SG_ALB_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --endpoint-url=http://localhost:4566
verificar "Agregar Regla 1 (HTTP Puerto 80) a SG ALB"

# REGLA 2: Permitir entrada web segura (Puerto 443 - HTTPS) desde cualquier origen al balanceador
aws ec2 authorize-security-group-ingress --group-id $SG_ALB_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --endpoint-url=http://localhost:4566
verificar "Agregar Regla 2 (HTTPS Puerto 443) a SG ALB"

# 2. Crear el Grupo de Seguridad para la Base de Datos RDS (Privado)
SG_RDS_ID=$(aws ec2 create-security-group --group-name acme-rds-sg --description "Firewall interno para la base de datos" --vpc-id $VPC_ID --query 'GroupId' --output text --endpoint-url=http://localhost:4566)
verificar "Creación de Grupo de Seguridad para RDS"

# REGLA 3: Permitir tráfico al puerto 5432 (PostgreSQL) SOLO para recursos dentro de la red (10.0.0.0/16)
aws ec2 authorize-security-group-ingress --group-id $SG_RDS_ID --protocol tcp --port 5432 --cidr 10.0.0.0/16 --endpoint-url=http://localhost:4566
verificar "Agregar Regla 3 (PostgreSQL Puerto 5432) a SG RDS"

# Vincular el grupo de seguridad privado a la instancia RDS de PostgreSQL creada en la Lección 2
aws rds modify-db-instance \
  --db-instance-identifier acme-postgres-db \
  --vpc-security-group-ids $SG_RDS_ID \
  --endpoint-url=http://localhost:4566
verificar "Vincular Grupo de Seguridad a Instancia RDS"

# Configurar la Lambda para que tenga interfaces de red (ENI) dentro de la subred privada de la VPC
aws lambda update-function-configuration \
  --function-name AcmeProcesarVentas \
  --vpc-config SubnetIds=$SUBNET_PRIV_A_ID,SecurityGroupIds=$SG_RDS_ID \
  --endpoint-url=http://localhost:4566
verificar "Asociar Lambda a la VPC (Subred Privada)"

# Crear el Balanceador de Carga de Aplicaciones (ALB) asociado a las subredes públicas en 2 AZs
aws elbv2 create-load-balancer \
  --name acme-web-alb \
  --subnets $SUBNET_PUB_A_ID $SUBNET_PUB_B_ID \
  --security-groups $SG_ALB_ID \
  --endpoint-url=http://localhost:4566
verificar "Creación de Balanceador de Carga ALB"

# Verificación de la Parte 5
echo "Verificando recursos de la Parte 5..."
aws ec2 describe-vpcs --vpc-ids $VPC_ID --endpoint-url=http://localhost:4566 >/dev/null
verificar "VPC con ID $VPC_ID es válida"
aws elbv2 describe-load-balancers --names acme-web-alb --endpoint-url=http://localhost:4566 >/dev/null
verificar "Balanceador ALB acme-web-alb está activo en Floci"


echo "========================================================================="
# PARTE 7: SERVICIOS SIMPLES DE ALOJAMIENTO WEB Y CONTENIDOS
echo "Ejecutando PARTE 7: SERVICIOS SIMPLES DE ALOJAMIENTO WEB Y CONTENIDOS..."
# =========================================================================

# 1. Crear el bucket exclusivo para el Frontend Web de ACME
aws s3api create-bucket --bucket acme-sitio-web-frontend --endpoint-url=http://localhost:4566
verificar "Creación de bucket acme-sitio-web-frontend"

# 2. Configurar el bucket en modo alojamiento web estático (buscando index.html)
aws s3api put-bucket-website --bucket acme-sitio-web-frontend --website-configuration '{"IndexDocument": {"Suffix": "index.html"}}' --endpoint-url=http://localhost:4566
verificar "Configuración de hosting estático en bucket"

# Crear la distribución de CloudFront apuntando al bucket de S3 como origen
aws cloudfront create-distribution \
  --origin-domain-name acme-sitio-web-frontend.s3.amazonaws.com \
  --endpoint-url=http://localhost:4566
verificar "Creación de la distribución de CloudFront"

# Verificación de la Parte 7
echo "Verificando recursos de la Parte 7..."
aws s3api get-bucket-website --bucket acme-sitio-web-frontend --endpoint-url=http://localhost:4566 >/dev/null
verificar "Bucket configurado para hosting web estático"
aws cloudfront list-distributions --endpoint-url=http://localhost:4566 >/dev/null
verificar "CloudFront tiene distribuciones registradas en Floci"


echo "========================================================================="
# PARTE 6: NOTIFICACIÓN Y MENSAJERÍA
echo "Ejecutando PARTE 6: NOTIFICACIÓN Y MENSAJERÍA..."
# =========================================================================

# Crear el tema SNS y obtener su ARN
TOPIC_ARN=$(aws sns create-topic \
  --name acme-alertas-operacionales \
  --query 'TopicArn' --output text \
  --endpoint-url=http://localhost:4566)
verificar "Creación de tema SNS acme-alertas-operacionales"

# Crear cola SQS y obtener su URL
COLA_URL=$(aws sqs create-queue \
  --queue-name acme-cola-eventos \
  --query 'QueueUrl' --output text \
  --endpoint-url=http://localhost:4566)
verificar "Creación de cola SQS acme-cola-eventos"

# Crear cola DLQ y obtener su URL
COLA_DLQ_URL=$(aws sqs create-queue \
  --queue-name acme-cola-eventos-dlq \
  --query 'QueueUrl' --output text \
  --endpoint-url=http://localhost:4566)
verificar "Creación de cola SQS DLQ acme-cola-eventos-dlq"

# Obtener los ARNs de las colas para las suscripciones
COLA_ARN=$(aws sqs get-queue-attributes \
  --queue-url $COLA_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' --output text \
  --endpoint-url=http://localhost:4566)

COLA_DLQ_ARN=$(aws sqs get-queue-attributes \
  --queue-url $COLA_DLQ_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' --output text \
  --endpoint-url=http://localhost:4566)

# Suscribir la cola SQS al tema SNS
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $COLA_ARN \
  --endpoint-url=http://localhost:4566
verificar "Suscripción de cola SQS al tema SNS"

# Suscribir un email simulado al tema SNS
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol email \
  --notification-endpoint alertas@acme-empresa.com \
  --endpoint-url=http://localhost:4566
verificar "Suscripción de email al tema SNS"

# Configurar la política de reintentos (redrive policy)
aws sqs set-queue-attributes \
  --queue-url $COLA_URL \
  --attributes "{\"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"$COLA_DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\", \"VisibilityTimeout\": \"30\", \"MessageRetentionPeriod\": \"86400\"}" \
  --endpoint-url=http://localhost:4566
verificar "Configurar política de Dead-Letter Queue (DLQ) en SQS"

# --- PRUEBA DE FLUJO DE MENSAJERÍA ---
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message "ALERTA: Evento operacional de prueba generado por ACME" \
  --subject "Alerta Operacional ACME" \
  --endpoint-url=http://localhost:4566
verificar "Publicación de mensaje de prueba en SNS"

aws sqs receive-message \
  --queue-url $COLA_URL \
  --endpoint-url=http://localhost:4566 >/dev/null
verificar "Lectura (recepción) de mensaje de prueba en cola SQS"


echo "========================================================================="
# PARTE 8: MONITOREO Y CORRELACIÓN DE INCIDENTES
echo "Ejecutando PARTE 8: MONITOREO Y CORRELACIÓN DE INCIDENTES..."
# =========================================================================

# Métrica 1: Invocaciones de la Lambda
aws cloudwatch put-metric-data \
  --namespace "AWS/Lambda" \
  --metric-name "Invocations" \
  --dimensions Name=FunctionName,Value=AcmeProcesarVentas \
  --value 10 \
  --unit Count \
  --endpoint-url=http://localhost:4566
verificar "Publicación de métrica 1 (Invocations)"

# Métrica 2: Errores de la Lambda
aws cloudwatch put-metric-data \
  --namespace "AWS/Lambda" \
  --metric-name "Errors" \
  --dimensions Name=FunctionName,Value=AcmeProcesarVentas \
  --value 0 \
  --unit Count \
  --endpoint-url=http://localhost:4566
verificar "Publicación de métrica 2 (Errors)"

# Métrica 3: Mensajes SQS visibles
aws cloudwatch put-metric-data \
  --namespace "AWS/SQS" \
  --metric-name "ApproximateNumberOfMessagesVisible" \
  --dimensions Name=QueueName,Value=acme-cola-eventos \
  --value 0 \
  --unit Count \
  --endpoint-url=http://localhost:4566
verificar "Publicación de métrica 3 (SQS Messages)"

# ALARMA 1: Monitorea errores de Lambda
aws cloudwatch put-metric-alarm \
  --alarm-name "acme-alarma-errores-criticos" \
  --alarm-description "Alarma: Se detectaron errores críticos en la función Lambda de ACME" \
  --namespace "AWS/Lambda" \
  --metric-name "Errors" \
  --dimensions Name=FunctionName,Value=AcmeProcesarVentas \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions $TOPIC_ARN \
  --endpoint-url=http://localhost:4566
verificar "Creación de Alarma CloudWatch 1 (Errores Lambda)"

# ALARMA 2: Monitorea mensajes SQS
aws cloudwatch put-metric-alarm \
  --alarm-name "acme-alarma-cola-saturada" \
  --alarm-description "Alarma: La cola SQS de ACME tiene demasiados mensajes pendientes" \
  --namespace "AWS/SQS" \
  --metric-name "ApproximateNumberOfMessagesVisible" \
  --dimensions Name=QueueName,Value=acme-cola-eventos \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 100 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --alarm-actions $TOPIC_ARN \
  --endpoint-url=http://localhost:4566
verificar "Creación de Alarma CloudWatch 2 (Saturación SQS)"

# Crear el grupo de logs (solo si no existe, ya que la invocación de Lambda en la Parte 4 puede crearlo automáticamente)
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/AcmeProcesarVentas --endpoint-url=http://localhost:4566 | grep -q "/aws/lambda/AcmeProcesarVentas"
if [ $? -ne 0 ]; then
  aws logs create-log-group \
    --log-group-name /aws/lambda/AcmeProcesarVentas \
    --endpoint-url=http://localhost:4566
  verificar "Creación de Grupo de Logs para Lambda"
else
  echo "⚠️ El Grupo de Logs /aws/lambda/AcmeProcesarVentas ya existe (creado automáticamente por Lambda), omitiendo creación."
fi

# Crear el stream de logs (solo si no existe)
aws logs describe-log-streams --log-group-name /aws/lambda/AcmeProcesarVentas --log-stream-name-prefix acme-stream-principal --endpoint-url=http://localhost:4566 2>/dev/null | grep -q "acme-stream-principal"
if [ $? -ne 0 ]; then
  aws logs create-log-stream \
    --log-group-name /aws/lambda/AcmeProcesarVentas \
    --log-stream-name acme-stream-principal \
    --endpoint-url=http://localhost:4566
  verificar "Creación de Stream de Logs"
else
  echo "⚠️ El Stream de Logs acme-stream-principal ya existe, omitiendo creación."
fi

# Establecer política de retención
aws logs put-retention-policy \
  --log-group-name /aws/lambda/AcmeProcesarVentas \
  --retention-in-days 30 \
  --endpoint-url=http://localhost:4566
verificar "Configuración de retención de logs (30 días)"

# Verificación de la Parte 8
echo "Verificando recursos de la Parte 8..."
aws cloudwatch describe-alarms --alarm-names "acme-alarma-errores-criticos" "acme-alarma-cola-saturada" --endpoint-url=http://localhost:4566 >/dev/null
verificar "Alarmas CloudWatch existen y están activas en Floci"
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/AcmeProcesarVentas --endpoint-url=http://localhost:4566 >/dev/null
verificar "Grupo de Logs CloudWatch es visible en Floci"

echo -e "\n========================================================================="
echo -e "\e[32m🎉 [DESPLIEGUE FINALIZADO EXITOSAMENTE] Todos los recursos se han creado y verificado.\e[0m"
echo "========================================================================="