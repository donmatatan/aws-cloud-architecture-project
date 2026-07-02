# 🚀 Proyecto de Portafolio 4: Infraestructura Viva (ACME)

Este proyecto implementa y despliega de manera automatizada la arquitectura en la nube para la infraestructura de **ACME**, migrando sus servicios locales hacia una solución robusta en AWS simulada mediante **Floci**. 

La arquitectura abarca desde el almacenamiento seguro y bases de datos gestionadas (SQL/NoSQL) hasta redes privadas y públicas, sistemas serverless, mensajería distribuida y un plan proactivo de monitoreo con alarmas.

---

## 🛠️ Prerrequisitos (Entorno Linux)

Para ejecutar este despliegue de manera local, asegúrate de contar con las siguientes herramientas en tu sistema operativo Linux:

1. **Docker y Docker Compose**: Para levantar el entorno de simulación local de AWS (Floci).
2. **AWS CLI**: La interfaz de línea de comandos de AWS configurada para apuntar al endpoint local.
3. **Python 3.x**: Requerido para la lógica interna y ejecución de la función Lambda.
4. **Herramienta `zip`**: Necesaria para empaquetar el código de la función Lambda antes del despliegue.

---

## ⚙️ Preparación del Entorno

1. **Iniciar el contenedor de Floci/LocalStack**:
   Encuentra el archivo `docker-compose.yml` en la raíz del proyecto y levanta el servicio ejecutando en tu terminal:
   ```bash
   docker-compose up -d
   ```

2. **Verificar que el servicio local esté activo**:
   ```bash
   curl http://localhost:4566/_localstack/health
   ```

---

## 🚀 Despliegue Automatizado

El despliegue completo de las 8 partes del portafolio se realiza a través del script principal corregido y validado contra fallas.

1. Conceder permisos de ejecución al script:
   ```bash
   chmod +x despliegue.sh
   ```
2. Ejecutar el despliegue:
   ```bash
   ./despliegue.sh
   ```

---

## 🧪 Pruebas de Funcionamiento y Evidencias

Una vez finalizado el despliegue, puedes ejecutar diversas pruebas para recopilar evidencias para tu portafolio. Hemos organizado estas pruebas en archivos dedicados (a crear en el directorio `tests/`):

### 1. Verificación de Recursos del Sistema
El script automatizado de pruebas describe y lista todos los recursos creados en tu entorno virtual de AWS (S3, RDS, DynamoDB, Lambda, VPC, ALB, SNS/SQS, y CloudWatch).
* **Script de prueba:** `[tests/verificar_despliegue.sh](file:///home/jairo/Documentos/BOOTCAMP%20ARQUITECTO%20CLOUD/tests/verificar_despliegue.sh)` *(Pendiente de crear)*

### 2. Consultas Relacionales (Lección 2)
Para simular el comportamiento de consultas SQL complejas requeridas por el bootcamp, puedes utilizar el archivo de scripts SQL en herramientas como SQLiteOnline con dialecto PostgreSQL.
* **Script SQL de prueba:** `[tests/consultas_prueba.sql](file:///home/jairo/Documentos/BOOTCAMP%20ARQUITECTO%20CLOUD/tests/consultas_prueba.sql)` *(Pendiente de crear)*

### 3. Simulación de Alertas de Monitoreo (Lección 8)
Prueba que inyecta métricas de falla simuladas para cambiar el estado de las alarmas de CloudWatch a `ALARM` y comprobar la integración con las notificaciones de SNS.
* **Script de simulación:** `[tests/simular_alerta.sh](file:///home/jairo/Documentos/BOOTCAMP%20ARQUITECTO%20CLOUD/tests/simular_alerta.sh)` *(Pendiente de crear)*

---

## 📄 Entregables y Documentación

* **[Informe de Arquitectura y Justificación de Solución](file:///home/jairo/Documentos/BOOTCAMP%20ARQUITECTO%20CLOUD/docs/informe_arquitectura.md)** *(Pendiente de vincular)*
  *Este documento detalla los diagramas de arquitectura, las justificaciones de uso de cada servicio y la estrategia de escalabilidad y costos estimados.*
