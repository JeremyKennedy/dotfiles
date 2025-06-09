# Claude AI Assistant Context

This file contains information for AI assistants working on this project.

## Project Location

This project is located in Jeremy's dotfiles repository at:
- **Path**: `~/dotfiles/nix/nixos/scripts/mqtt-service/`
- **Repository**: Personal NixOS/home-manager configuration dotfiles
- **Integration**: Part of NixOS system configuration in `nixos/scripts/`

## Project Overview

**MQTT Service** is a Python daemon that provides MQTT-based control for system volume and gaming mode functionality. It connects to a local MQTT broker and responds to commands for volume control and display configuration changes.

## Key Technical Details

### Architecture
- **Language**: Python 3.12+ with paho-mqtt
- **MQTT Client**: paho-mqtt for reliable broker communication
- **Audio Control**: wpctl (WirePlumber) for PipeWire volume management
- **Display Control**: hyprctl for Hyprland window manager configuration
- **Deployment**: NixOS systemd service running under user "jeremy"

### MQTT Integration
- **Broker**: Local MQTT broker at 192.168.1.240:1883
- **Topics**:
  - `home/office/volume` - Volume control commands
  - `home/office/game-mode` - Gaming mode toggle commands
- **QoS Level**: 1 (at least once delivery)

### Functionality

#### Volume Control
Commands via `home/office/volume`:
- `mute` - Mute system audio
- `unmute` - Unmute system audio
- `0-100` - Set volume percentage
- `+5`, `-5` - Relative volume adjustment

#### Game Mode
Commands via `home/office/game-mode`:
- `on` - Enable gaming configuration:
  - Enable HDMI-A-1 monitor (3840x2160@144Hz)
  - Position cursor at bottom-right of HDMI display
  - Set volume to 80% and unmute
- `off` - Disable gaming configuration:
  - Disable HDMI-A-1 monitor
  - Restore previous audio state

### System Integration
- **User Context**: Runs as "jeremy" user with Wayland/Hyprland access
- **Environment Variables**: Configured for Wayland session access
- **Auto-restart**: Systemd automatically restarts on failure
- **Logging**: Comprehensive logging via Python logging module

## Development Guidelines

### When modifying this project:

1. **Maintain MQTT reliability** - Ensure proper connection handling and reconnection
2. **Preserve Wayland integration** - Keep environment variables for Hyprland access
3. **Test volume commands** - Verify wpctl commands work in target environment
4. **Handle display edge cases** - Gaming mode should gracefully handle monitor availability
5. **Update documentation** when adding new MQTT topics or commands

### Common Tasks

**Adding new MQTT topics**:
```python
def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload.decode()
    
    if topic == "home/office/new-feature":
        handle_new_feature(payload)
```

**Adding volume presets**:
```python
elif payload == "gaming":
    run_command([WPCTL, "set-volume", "@DEFAULT_AUDIO_SINK@", "-l", "1.5", "0.8"])
```

**Testing changes**:
```bash
# Test volume control
mosquitto_pub -h 192.168.1.240 -t "home/office/volume" -m "50"

# Test game mode
mosquitto_pub -h 192.168.1.240 -t "home/office/game-mode" -m "on"
```

## Production Environment

### Service Configuration
- **Runtime**: Always-running systemd service
- **User**: `jeremy` (requires Wayland session access)
- **Auto-start**: Enabled with system boot
- **Dependencies**: Requires network and graphical session
- **Logs**: Available via `journalctl -u mqtt-service.service`

### Monitoring
- Check service status: `systemctl status mqtt-service.service`
- View recent logs: `journalctl -u mqtt-service.service --since "1 hour ago"`
- Manual restart: `sudo systemctl restart mqtt-service.service`
- Test MQTT connectivity: `mosquitto_sub -h 192.168.1.240 -t "home/office/#"`

## Dependencies

### Runtime Dependencies
- `paho-mqtt` - MQTT client library
- `wpctl` - WirePlumber audio control (system package)
- `hyprctl` - Hyprland window manager control (system package)

### NixOS Integration
The service.nix provides complete systemd integration:
- Python environment with paho-mqtt
- Proper user permissions and Wayland environment
- Automatic service restart and dependency management
- Script deployment to `/etc/mqtt-service/main.py`

## MQTT Protocol Details

### Message Format
All messages are UTF-8 encoded strings sent to specific topics.

### Topics and Payloads

**Volume Control** (`home/office/volume`):
- Numeric values: `0` through `100` (percentage)
- Commands: `mute`, `unmute`
- Relative: `+5`, `-5`, `+10`, `-10`

**Game Mode** (`home/office/game-mode`):
- `on` - Enable gaming setup
- `off` - Disable gaming setup

### Error Handling

The service handles these scenarios gracefully:
- MQTT broker disconnection and reconnection
- Invalid MQTT payloads or commands
- Missing wpctl or hyprctl system commands
- Monitor availability for gaming mode
- Audio device availability

## Testing Strategy

1. **Unit Testing**: Test individual command handlers
2. **Integration Testing**: Verify MQTT broker communication
3. **System Testing**: Test actual volume and display changes
4. **Error Testing**: Verify graceful handling of failures

## Maintenance Notes

- **MQTT broker changes**: Update broker IP in main.py if infrastructure changes
- **Audio system changes**: Verify wpctl commands if switching from PipeWire
- **Display changes**: Update monitor names/resolutions in game mode handlers
- **User changes**: Service must run as user with Wayland session access
- **Performance**: Service is lightweight, handles ~10 commands/second efficiently