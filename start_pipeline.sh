#!/bin/bash

set -e
echo ""
echo "🚀 Iniciando contenedores con Docker Compose..."
echo ""
docker compose up -d
echo ""
echo ""

echo "⏳ Iniciando Kafka Connect..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8083); do
  printf '.'
  sleep 5
done

echo ""

echo "✅ Registrando nuevo conector mqtt-source..."
echo ""

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
      "value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
  }'

until [[ "$(curl -s http://localhost:8083/connectors/mqtt-source/status | jq -r '.connector.state' 2>/dev/null)" == "RUNNING" ]]; do
  sleep 3
done



echo ""
echo ""
echo "📡 Estado del conector mqtt-source:"
curl -s http://localhost:8083/connectors/mqtt-source/status | jq .

sleep 10


#echo "✅ Registrando conector JDBC para MySQL..."
#curl -s -X POST http://localhost:8083/connectors \
#  -H "Content-Type: application/json" \
#  -d '{
#    "name": "jdbc-sink",
#    "config": {
#      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
#      "connection.url": "jdbc:mysql://mysql:3306/twitter_db?user=user&password=pass",
#      "topics": "tweets",
#      "auto.create": "true",
#      "insert.mode": "insert",  
#      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
#      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
#      "value.converter.schemas.enable": "false"
#    }
#  }'#

#until [[ "$(curl -s http://localhost:8083/connectors/jdbc-sink/status | jq -r '.connector.state' 2>/dev/null)" == "RUNNING" ]]; do
#  sleep 3
#done

#echo "📡 Estado del conector jdbc-sink:"
#curl -s http://localhost:8083/connectors/jdbc-sink/status | jq .


echo ""
echo "✅ Pipeline iniciado correctamente:"
echo ""
echo "Mensajes:"

docker exec -i kafka-connect kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic tweets \
  --from-beginning \
  --property print.value=true \
  --max-messages 3
