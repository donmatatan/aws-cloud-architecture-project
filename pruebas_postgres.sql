-- =========================================================================
-- PROYECTO INFRAESTRUCTURA VIVA - SOLUCIONES DIGITALES ACME
-- LECCIÓN 2: BASE DE DATOS RELACIONAL (POSTGRESQL)
-- Pruebas de consultas en SQLiteOnline (Modo PostgreSQL)
-- =========================================================================

-- -------------------------------------------------------------------------
-- PASO 1: CREACIÓN DE TABLAS Y RELACIONES (DDL)
-- -------------------------------------------------------------------------

-- Crear tabla de Clientes
CREATE TABLE clientes (
    cliente_id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(100),
    region VARCHAR(50)
);

-- Crear tabla de Ventas con clave foránea referenciando a Clientes
CREATE TABLE ventas (
    venta_id SERIAL PRIMARY KEY,
    cliente_id VARCHAR(50),
    monto DECIMAL(10,2),
    fecha DATE,
    estado VARCHAR(20),
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

-- -------------------------------------------------------------------------
-- PASO 2: INSERCIÓN DE DATOS DE PRUEBA (DML)
-- -------------------------------------------------------------------------

INSERT INTO clientes (cliente_id, nombre, region) VALUES
('CLI-001', 'Corporación ACME Latam', 'Sudamérica'),
('CLI-002', 'Tecnologías Globales', 'Norteamérica'),
('CLI-003', 'Servicios Industriales Pro', 'Europa'),
('CLI-004', 'Soporte Digital S.A.', 'Sudamérica');

INSERT INTO ventas (cliente_id, monto, fecha, estado) VALUES
('CLI-001', 1500.50, '2026-07-01', 'Procesado'),
('CLI-002', 450.00, '2026-07-02', 'Procesado'),
('CLI-001', 3200.00, '2026-07-03', 'Procesado'),
('CLI-003', 120.00, '2026-07-03', 'Pendiente'),
('CLI-004', 950.00, '2026-07-04', 'Procesado'),
('CLI-002', 2100.00, '2026-07-05', 'Cancelado');

-- -------------------------------------------------------------------------
-- PASO 3: CONSULTAS DE REPORTE Y VERIFICACIÓN (DML/QUERIES)
-- -------------------------------------------------------------------------

-- [Consulta 1]: Reporte de facturación por cliente (Suma y Agrupación)
-- Propósito: Obtener el monto total facturado por cliente para los pedidos ya procesados.
SELECT c.nombre, SUM(v.monto) AS total_facturado
FROM ventas v
JOIN clientes c ON v.cliente_id = c.cliente_id
WHERE v.estado = 'Procesado'
GROUP BY c.nombre
ORDER BY total_facturado DESC;


-- [Consulta 2]: Reporte de rendimiento por Región (Análisis comercial)
-- Propósito: Analizar la distribución de ventas e ingresos totales según la región geográfica.
SELECT c.region, COUNT(v.venta_id) AS cantidad_ventas, SUM(v.monto) AS ingresos_totales
FROM ventas v
JOIN clientes c ON v.cliente_id = c.cliente_id
WHERE v.estado = 'Procesado'
GROUP BY c.region;


-- [Consulta 3]: Transacciones de alto valor (Filtro mayor a $1,000 USD)
-- Propósito: Identificar las ventas individuales de alta prioridad para auditorías comerciales.
SELECT v.venta_id, c.nombre, v.monto, v.fecha
FROM ventas v
JOIN clientes c ON v.cliente_id = c.cliente_id
WHERE v.monto > 1000.00
ORDER BY v.monto DESC;


-- [Consulta 4]: Resumen operacional del estado de ventas
-- Propósito: Monitorear el flujo del pipeline comercial y volumen monetario según estado.
SELECT estado, COUNT(*) AS total_transacciones, SUM(monto) AS monto_total
FROM ventas
GROUP BY estado;
