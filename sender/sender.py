
import json
import numpy as np
from datetime import datetime
import time
import paho.mqtt.client as mqtt

json_file = '/app/data/tweets1.json'


gap = 4
with open(json_file, 'r') as file:
    tweets = json.load(file)
    client = mqtt.Client()
    client.connect("mosquitto", 1883, 60)

    while True:
        try:
            user = np.random.randint(len(tweets))
            if not tweets[user]["tweets"]:
                continue  # salta a la siguiente iteración
            tweet = np.random.randint(len(tweets[user]["tweets"]))
            # Produce the JSON data to the Kafka topic
            now = datetime.now()
            formatted = now.strftime("%Y-%m-%d %H:%M:%S")
            text = tweets[user]["tweets"][tweet].encode('utf-8','ignore').decode("utf-8").replace('\n', ' ')
            text += "."
            text = text.replace('"', "")
            text = text.replace('\\', "")
            #tweets[user]["tweets"][tweet].encode("utf-8").decode('utf-8','ignore')


            message = {
                "user_id": tweets[user]["id"],
                "tweet": text,
                "timestamp": formatted
            }
            client.publish("tweets", json.dumps(message, ensure_ascii=False)) # TODO Verificar si funciona 
            #client.publish("tweets", json.dumps(message).encode('utf-8'))
            print("Publicado:", message)
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
            # Introduce a delay between insertions
            time.sleep(gap)

