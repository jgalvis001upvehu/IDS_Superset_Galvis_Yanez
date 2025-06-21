#!/bin/bash
set -e

echo "🚀 Procesando datos para Hive dentro del contenedor..."

# 1. Convertir JSON a JSONL
jq -c '.[]' /workspace/data/users1.json > /workspace/data/users1_lines.json

jq -c 'map({
  id,
  follows: (if (.follows | type) == "string" then (.follows | split(",") | map(tonumber)) else .follows end),
  is_followed_by: (if (.is_followed_by | type) == "string" then (.is_followed_by | split(",") | map(tonumber)) else .is_followed_by end)
})[]' /workspace/data/edges1.json > /workspace/data/edges1_lines.json

jq -c '.[] | {id, tweets}' /workspace/data/tweets1.json > /workspace/data/tweets1_lines.json


# 2. Organizar carpetas
mkdir -p /workspace/data/mbti_labels_csv
cp /workspace/data/mbti_labels.csv /workspace/data/mbti_labels_csv/

mkdir -p /workspace/data/users1_json
cp /workspace/data/users1_lines.json /workspace/data/users1_json/

mkdir -p /workspace/data/edges1_json
cp /workspace/data/edges1_lines.json /workspace/data/edges1_json/

mkdir -p /workspace/data/tweets1_json
cp /workspace/data/tweets1_lines.json /workspace/data/tweets1_json/

# 3. Esperar que Hive esté disponible
echo "⏳ Verificando conexión a Hive..."
until beeline -u jdbc:hive2://hive:10000 -n hive -e "SHOW DATABASES;" >/dev/null 2>&1; do
  echo "⏳ Hive no disponible aún. Reintentando..."
  sleep 5
done

# 4. Crear tablas
beeline -u jdbc:hive2://hive:10000 -n hive -e "
CREATE EXTERNAL TABLE IF NOT EXISTS mbti_labels (
  id BIGINT,
  mbti_personality STRING,
  pers_id BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/workspace/data/mbti_labels_csv'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE IF NOT EXISTS users1 (
  screen_name STRING,
  location STRING,
  verified BOOLEAN,
  statuses_count INT,
  total_retweet_count INT,
  total_favorite_count INT,
  total_hashtag_count INT,
  total_mentions_count INT,
  total_media_count INT,
  id BIGINT
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE
LOCATION '/workspace/data/users1_json';

CREATE EXTERNAL TABLE IF NOT EXISTS edges1 (
  id BIGINT,
  follows ARRAY<BIGINT>,
  is_followed_by ARRAY<BIGINT>
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE
LOCATION '/workspace/data/edges1_json';

CREATE EXTERNAL TABLE IF NOT EXISTS tweets1 (
  id BIGINT,
  tweets ARRAY<STRING>
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE
LOCATION '/workspace/data/tweets1_json';

SHOW TABLES;
SELECT 'users1:', COUNT(*) FROM users1;
SELECT 'edges1:', COUNT(*) FROM edges1;
SELECT 'mbti_labels:', COUNT(*) FROM mbti_labels;
SELECT 'tweets1:', COUNT(*) FROM tweets1;
"