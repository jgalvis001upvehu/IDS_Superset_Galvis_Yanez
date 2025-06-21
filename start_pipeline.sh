#!/bin/bash
set -e

echo -e "\n Starting containers with Docker Compose...\n"
docker compose up --build -d

echo -e "\n Waiting for Kafka Connect to be ready (8083)..."
until curl --silent --output /dev/null --head --fail http://localhost:8083; do
  printf '.'
  sleep 5
done
echo -e "\n Kafka Connect is ready."

# Check if the connector already exists
echo -e "\n Checking if the mqtt-source connector already exists..."
EXISTS=$(curl -s http://localhost:8083/connectors | jq -r '.[]' | grep -w mqtt-source || true)

# Connector configuration
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

# Register or update the connector
if [[ -n "$EXISTS" ]]; then
  echo -e "\n Connector already exists."
  RESPONSE=$(curl -s -X PUT http://localhost:8083/connectors/mqtt-source/config \
              -H "Content-Type: application/json" \
              -d "$CONNECTOR_PAYLOAD")
else
  echo -e "\n Registering new MQTT → Kafka connector..."
  RESPONSE=$(curl -s -X POST http://localhost:8083/connectors \
              -H "Content-Type: application/json" \
              -d '{"name": "mqtt-source", "config": '"$CONNECTOR_PAYLOAD"'}')
fi

echo -e "\n Connector registration response:\n$RESPONSE"

# Wait for the connector to reach RUNNING state
echo -e "\n Waiting for the connector to enter RUNNING state…"
until [[ "$(curl -s http://localhost:8083/connectors/mqtt-source/status | jq -r '.connector.state' 2>/dev/null)" == "RUNNING" ]]; do
  sleep 3
done
echo " Connector is RUNNING."

# Show detailed connector status
echo -e "\n Detailed connector status:"
curl -s http://localhost:8083/connectors/mqtt-source/status | jq .

sleep 5

# Show first messages from the topic
echo -e "\n First messages received on Kafka topic «tweets»:\n"
docker exec -it kafka-connect \
  kafka-console-consumer \
    --bootstrap-server kafka:9092 \
    --topic tweets \
    --from-beginning \
    --property print.value=true \
    --max-messages 3

    
echo -e "\n Kafka is working."

docker run -d --name druid \
  --network kafka-net \
  -p 8888:8888 -p 8082:8082 -p 8081:8081 \
  -e DRUID_XMS=512m -e DRUID_XMX=1g \
  -e DRUID_EXTENSIONS_LOADLIST='["druid-kafka-indexing-service"]' \
  fokkodriesprong/docker-druid

echo -n "Waiting for Druid Router"
until curl -sf http://localhost:8888/status/health ; do printf '.'; sleep 5; done
echo "Droud Router is operational"

# Publish the supervisor …
curl -sfX POST http://localhost:8081/druid/indexer/v1/supervisor \
     -H 'Content-Type: application/json' \
     -d @druid_kafka_spec.json | jq .

echo -e "\n All set."
