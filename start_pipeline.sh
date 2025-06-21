#!/bin/bash
set -e

echo -e "\n Iniciando contenedores con Docker Compose...\n"
docker compose up --build -d

echo -e "\n Esperando a que Kafka Connect levante (8083)..."
until curl --silent --output /dev/null --head --fail http://localhost:8083; do
  printf '.'
  sleep 5
done
echo -e "\n Kafka Connect listo."

# Verifica si el conector ya existe
echo -e "\n🔍 Verificando si el conector mqtt-source ya existe..."
EXISTS=$(curl -s http://localhost:8083/connectors | jq -r '.[]' | grep -w mqtt-source || true)

# Configuración del conector
CONNECTOR_PAYLOAD='{
  "connector.class": "io.confluent.connect.mqtt.MqttSourceConnector",
  "tasks.max": 1,
  "mqtt.server.uri": "tcp://mosquitto:1883",
  "mqtt.topics": "tweets",
  "kafka.topic": "tweets",
  "value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter",
  "confluent.topic.bootstrap.servers": "kafka:9092",
  "confluent.topic.replication.factor": 1
}'

# Registra o actualiza el conector
if [[ -n "$EXISTS" ]]; then
  echo -e "\n Conector ya existe."
  RESPONSE=$(curl -s -X PUT http://localhost:8083/connectors/mqtt-source/config \
              -H "Content-Type: application/json" \
              -d "$CONNECTOR_PAYLOAD")
else
  echo -e "\n Registrando nuevo conector MQTT → Kafka..."
  RESPONSE=$(curl -s -X POST http://localhost:8083/connectors \
              -H "Content-Type: application/json" \
              -d '{"name": "mqtt-source", "config": '"$CONNECTOR_PAYLOAD"'}')
fi

echo -e "\n Respuesta al registrar el conector:\n$RESPONSE"

# Esperar a que el conector esté en estado RUNNING
echo -e "\n Esperando a que el conector entre en estado RUNNING…"
until [[ "$(curl -s http://localhost:8083/connectors/mqtt-source/status | jq -r '.connector.state' 2>/dev/null)" == "RUNNING" ]]; do
  sleep 3
done
echo " Conector RUNNING."

# Mostrar estado detallado
echo -e "\n Estado detallado del conector:"
curl -s http://localhost:8083/connectors/mqtt-source/status | jq .

sleep 5

# Mostrar primeros mensajes del topic
echo -e "\n Primeros mensajes recibidos en el topic Kafka «tweets»:\n"
docker exec -it kafka-connect \
  kafka-console-consumer \
    --bootstrap-server kafka:9092 \
    --topic tweets \
    --from-beginning \
    --property print.value=true \
    --max-messages 3

    
echo -e "\n Pipeline MQTT → Kafka operativo."

docker run -d --name druid \
  --network kafka-net \
  -p 8888:8888 -p 8082:8082 -p 8081:8081 \
  -e DRUID_XMS=512m -e DRUID_XMX=1g \
  -e DRUID_EXTENSIONS_LOADLIST='["druid-kafka-indexing-service"]' \
  fokkodriesprong/docker-druid

echo -n "⏳ Esperando Druid Router"
until curl -sf http://localhost:8888/status/health ; do printf '.'; sleep 5; done
echo " ✔︎"

# publica el supervisor …
curl -sfX POST http://localhost:8081/druid/indexer/v1/supervisor \
     -H 'Content-Type: application/json' \
     -d @druid_kafka_spec.json | jq .

echo -e "\n✅  Todo listo."

