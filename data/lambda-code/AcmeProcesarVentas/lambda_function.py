import json
import time

def lambda_handler(event, context):
    # Simula un procesamiento pesado en el procesador (CPU)
    inicio = time.time()
    contador = 0
    for i in range(1000000):
        contador += i
    fin = time.time()

    return {
        'statusCode': 200,
        'body': json.dumps({
            'mensaje': 'Reporte de ventas ACME procesado con exito',
            'tiempo_procesamiento_segundos': fin - inicio
        })
    }