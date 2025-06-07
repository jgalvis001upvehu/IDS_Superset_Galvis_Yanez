#!/bin/bash

set -e

echo "🚀 Iniciando contenedores con Docker Compose..."
docker-compose up -d

echo "⏳ Esperando 300 segundos para que los servicios estén listos..."
sleep 300


echo "✅ Registrando nuevo conector mqtt-source con JsonConverter..."

curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mqtt-source",
    "config": {
      "connector.class": "com.datamountaineer.streamreactor.connect.mqtt.source.MqttSourceConnector",
      "tasks.max": "1",
      "connect.mqtt.hosts": "tcp://mosquitto:1883",
      "connect.mqtt.kcql": "INSERT INTO tweets SELECT * FROM tweets",
      "connect.mqtt.service.quality": "1",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false"
    }
  }'

echo ""
echo "📡 Estado del conector mqtt-source:"
curl -s http://localhost:8083/connectors/mqtt-source/status | jq .

echo ""
echo "✅ Pipeline iniciado correctamente. Puedes verificar los mensajes con:"
docker exec -it kafka-connect kafka-console-consumer --bootstrap-server localhost:9092 --topic tweets --from-beginning --timeout-ms 5000 --max-messages 3
