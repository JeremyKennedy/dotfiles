#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import subprocess
import logging
import os

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s: %(message)s')
logging.info("Starting MQTT service")

MQTT_BROKER = "192.168.1.240"
WPCTL = "/run/current-system/sw/bin/wpctl"
HYPRCTL = "/run/current-system/sw/bin/hyprctl"

def get_hyprland_signature():
    """Get HYPRLAND_INSTANCE_SIGNATURE from user session"""
    try:
        # Try to get from user's environment via systemctl
        result = subprocess.run(['systemctl', '--user', 'show-environment'], 
                              capture_output=True, text=True, check=True)
        for line in result.stdout.split('\n'):
            if line.startswith('HYPRLAND_INSTANCE_SIGNATURE='):
                return line.split('=', 1)[1]
    except:
        pass
    
    # Fallback: try to read from user session via proc
    try:
        # Find Hyprland process
        result = subprocess.run(['pgrep', '-u', '1000', 'Hyprland'], 
                              capture_output=True, text=True, check=True)
        pid = result.stdout.strip().split('\n')[0]
        
        # Read environment from proc
        with open(f'/proc/{pid}/environ', 'rb') as f:
            env_data = f.read().decode('utf-8', errors='ignore')
            for env_var in env_data.split('\0'):
                if env_var.startswith('HYPRLAND_INSTANCE_SIGNATURE='):
                    return env_var.split('=', 1)[1]
    except:
        pass
    
    return None

# Set environment variables for Wayland/Hyprland
signature = get_hyprland_signature()
if signature:
    os.environ['HYPRLAND_INSTANCE_SIGNATURE'] = signature
    logging.info(f"Found HYPRLAND_INSTANCE_SIGNATURE: {signature[:32]}...")
else:
    logging.warning("Could not find HYPRLAND_INSTANCE_SIGNATURE")

os.environ.update({
    'WAYLAND_DISPLAY': 'wayland-1',
    'XDG_SESSION_TYPE': 'wayland',
    'QT_QPA_PLATFORM': 'wayland',
    'GDK_BACKEND': 'wayland',
})

def run_command(cmd, check=True):
    """Execute command with error handling and logging"""
    try:
        result = subprocess.run(cmd, check=check, capture_output=True, text=True)
        logging.info(f"Command executed: {' '.join(cmd)}")
        return result
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed: {' '.join(cmd)} - {e.stderr}")
        raise

def handle_volume(payload):
    """Handle volume control messages"""
    try:
        level = int(payload)
        level = max(0, min(level, 150))  # clamp volume between 0 and 150
        logging.info(f"Setting volume to {level}%")
        
        # mute if zero, unmute otherwise
        if level > 0:
            run_command([WPCTL, "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
        else:
            run_command([WPCTL, "set-mute", "@DEFAULT_AUDIO_SINK@", "1"])
        
        # set volume (0.0–1.5) with max limit 1.5
        vol_frac = level / 100.0
        run_command([WPCTL, "set-volume", "@DEFAULT_AUDIO_SINK@", "-l", "1.5", str(vol_frac)])
        
    except ValueError:
        logging.warning(f"Ignoring non-integer volume payload: {payload}")

def handle_game_mode(payload):
    """Handle game mode enable/disable messages"""
    try:
        enable = payload.lower() in ['1', 'true', 'on', 'enable']
        logging.info(f"Game mode: {'enabling' if enable else 'disabling'}")
        
        if enable:
            # Enable HDMI-A-1 monitor
            run_command([HYPRCTL, "keyword", "monitor", "HDMI-A-1, 3840x2160@144, 3840x880, 1"])
            logging.info("Enabled HDMI-A-1 monitor")
            
            # Move cursor to bottom right of HDMI-A-1 (3840x2160 resolution at offset 3840x880)
            cursor_x = 3840 + 3840 - 10  # Right edge of HDMI-A-1 minus small margin
            cursor_y = 880 + 2160 - 10   # Bottom edge of HDMI-A-1 minus small margin
            run_command([HYPRCTL, "dispatch", "movecursor", str(cursor_x), str(cursor_y)])
            logging.info(f"Moved cursor to bottom right of HDMI-A-1 ({cursor_x}, {cursor_y})")
            
            # Set volume to 80% and unmute
            run_command([WPCTL, "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
            run_command([WPCTL, "set-volume", "@DEFAULT_AUDIO_SINK@", "-l", "1.5", "0.8"])
            logging.info("Set volume to 80%")
            
            # Kill parsec if running
            try:
                run_command(["killall", "parsecd"], check=False)
                logging.info("Killed parsecd")
            except:
                logging.info("parsecd not running")
            
            # Launch Steam
            try:
                subprocess.Popen(["steam"], 
                               env=os.environ.copy(),
                               stdout=subprocess.DEVNULL, 
                               stderr=subprocess.DEVNULL)
                logging.info("Launched Steam")
            except Exception as e:
                logging.error(f"Failed to launch Steam: {e}")
        else:
            # Disable HDMI-A-1 monitor
            try:
                run_command([HYPRCTL, "keyword", "monitor", "HDMI-A-1, disable"], check=False)
                logging.info("Disabled HDMI-A-1 monitor")
            except:
                logging.info("HDMI-A-1 already disabled or not found")
                
    except Exception as e:
        logging.error(f"Game mode handler error: {e}")

# Topic handlers mapping
TOPIC_HANDLERS = {
    "home/pc/volume/set": handle_volume,
    "home/pc/gamemode/set": handle_game_mode,
}

def on_connect(client, userdata, flags, rc, properties=None):
    """Handle MQTT connection"""
    for topic in TOPIC_HANDLERS.keys():
        client.subscribe(topic)
        logging.info(f"Subscribed to {topic}")
    logging.info(f"Connected to MQTT broker {MQTT_BROKER}")

def on_message(client, userdata, msg):
    """Handle incoming MQTT messages"""
    topic = msg.topic
    payload = msg.payload.decode().strip()
    logging.info(f"Received message on {topic}: {payload}")
    
    handler = TOPIC_HANDLERS.get(topic)
    if handler:
        try:
            handler(payload)
        except Exception as e:
            logging.error(f"Handler error for {topic}: {e}")
    else:
        logging.warning(f"No handler for topic: {topic}")

# Setup MQTT client
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_BROKER, 1883, 60)
logging.info(f"Initiated connection to broker at {MQTT_BROKER}")
client.loop_forever()