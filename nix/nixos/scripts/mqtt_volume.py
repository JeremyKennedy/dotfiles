#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import subprocess
import logging

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s: %(message)s')
logging.info("Starting MQTT volume subscriber")

MQTT_BROKER = "192.168.1.240"
MQTT_TOPIC = "home/pc/volume/set"
WPCTL = "/run/current-system/sw/bin/wpctl"

def on_connect(client, userdata, flags, rc, properties=None):
    client.subscribe(MQTT_TOPIC)
    logging.info(f"Connected to MQTT broker {MQTT_BROKER}, subscribed to {MQTT_TOPIC}")

def on_message(client, userdata, msg):
    logging.info(f"Received message on {msg.topic}: {msg.payload.decode()}")
    try:
        level = int(msg.payload)
        # clamp volume between 0 and 150
        level = max(0, min(level, 150))
        logging.info(f"Setting volume to {level}%")
        # mute if zero, unmute otherwise
        if level > 0:
            subprocess.run([WPCTL, "set-mute", "@DEFAULT_AUDIO_SINK@", "0"], check=True)
        else:
            subprocess.run([WPCTL, "set-mute", "@DEFAULT_AUDIO_SINK@", "1"], check=True)
        # set volume (0.0–1.5) with max limit 1.5
        vol_frac = level / 100.0
        subprocess.run([WPCTL, "set-volume", "@DEFAULT_AUDIO_SINK@", "-l", "1.5", str(vol_frac)], check=True)
    except ValueError:
        logging.warning(f"Ignoring non-integer payload: {msg.payload}")
        pass

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_BROKER, 1883, 60)
logging.info(f"Initiated connection to broker at {MQTT_BROKER}")
client.loop_forever() 