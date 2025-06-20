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
                continue

            tweet = np.random.randint(len(tweets[user]["tweets"]))
            text = tweets[user]["tweets"][tweet].replace('\n', ' ').replace('"', '').replace('\\', '').strip()

            message = {
                "user_id": tweets[user]["id"],
                "tweet": text,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }

            client.publish("tweets", json.dumps(message).encode('utf-8'))
            print("Publicado:", message)
            time.sleep(gap)

        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
            time.sleep(gap)
