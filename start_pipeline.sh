#!/bin/bash
set -e

echo -e "\n Iniciando contenedores con Docker Compose...\n"
docker compose up -d

echo -e "\n Esperando a que Kafka Connect levante (8083)..."
until curl --silent --output /dev/null --head --fail http://localhost:8083; do
  printf '.'
  sleep 5
done
echo -e "\n Kafka Connect listo."

# Verifica si el conector ya existe
echo -e "\n🔍 Verificando si el conector mqtt-source ya existe..."
EXISTS=$(curl -s http://localhost:8083/connectors | jq -r '.[]' | grep -w mqtt-source || true)

# Payload del conector MQTT
CONNECTOR_PAYLOAD='{
  "connector.class": "com.datamountaineer.streamreactor.connect.mqtt.source.MqttSourceConnector",
  "tasks.max": "1",
  "connect.mqtt.hosts": "tcp://mosquitto:1883",
  "connect.mqtt.topics": "tweets",
  "connect.mqtt.client_id": "mqtt-kafka-bridge",
  "connect.mqtt.clean": "true",
  "connect.mqtt.timeout": "1000",
  "connect.mqtt.service.quality": "1",
  "connect.mqtt.kcql": "INSERT INTO tweets SELECT * FROM tweets",
  "value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter",
  "key.converter": "org.apache.kafka.connect.storage.StringConverter"
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
    --bootstrap-server localhost:9092 \
    --topic tweets \
    --from-beginning \
    --property print.value=true \
    --max-messages 10
echo -e "\n Pipeline MQTT → Kafka operativo."

docker run -p 8081:8081 -p 8082:8082 -p 8888:8888 --network kafka-net -it fokkodriesprong/docker-druid



