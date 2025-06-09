# Grist Payment Date Updater

Automatically updates payment dates in your Grist table based on recurrence patterns (yearly, monthly, two weeks). Advances past due dates to the next future occurrence.

## Features

- 🔄 **Smart Date Advancement**: Automatically advances past dates to future
- 📅 **Multiple Recurrence Types**: Supports yearly, monthly, and two-week cycles  
- 🔒 **Safe by Default**: Dry-run mode prevents accidental changes
- 🚀 **NixOS Integration**: Ready-to-deploy systemd service
- 🕰️ **Scheduled Execution**: Runs daily at 8 AM via systemd timer
- 🔐 **Secure**: Uses API keys and Authelia proxy authentication

## Quick Start

### NixOS Service (Recommended)
1. **Configure Secrets**: Update `nix/secrets.json` with your credentials
2. **Deploy**: Service runs automatically at 8 AM daily

### Standalone Usage
1. **Setup Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your Grist API key and proxy auth
   ```

2. **Test in Dry-Run Mode** (safe - makes no changes):
   ```bash
   python3 main.py  # Runs in dry-run by default
   ```

3. **Run Live Updates**:
   ```bash
   echo "DRY_RUN=false" >> .env
   python3 main.py
   ```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GRIST_API_KEY` | *from secrets* | Your Grist API key (auto-configured) |
| `GRIST_PROXY_AUTH` | *from secrets* | Proxy auth header (auto-configured) |
| `DRY_RUN` | `true` | Set to `false` to make actual changes |

## Grist Table Requirements

Your Grist table must have these fields:
- **`Next_Payment`**: Date field (stored as Unix timestamp)
- **`Recurrence`**: Text field with values: `Yearly`, `Monthly`, `Two weeks`

## Example Updates

The script intelligently advances dates:
- **Monthly**: `2025-04-17` → `2025-06-17` (skips May since today is 2025-06-09)
- **Two weeks**: `2025-05-15` → `2025-06-12` 
- **Yearly**: `2024-09-08` → `2025-09-08`

## NixOS Service Deployment

### 1. Add to Your Configuration

Add to your `configuration.nix`:
```nix
imports = [ ./path/to/grist-payment-updater/service.nix ];
```

### 2. Deploy and Enable

```bash
sudo nixos-rebuild switch
sudo systemctl enable grist-payment-updater.timer
sudo systemctl start grist-payment-updater.timer
```

## Service Management

### Check Timer Status
```bash
systemctl status grist-payment-updater.timer
systemctl list-timers grist-payment-updater*
```

### Manual Execution
```bash
sudo systemctl start grist-payment-updater.service
```

### View Logs
```bash
# Real-time logs
journalctl -u grist-payment-updater.service -f

# Recent logs
journalctl -u grist-payment-updater.service --since "1 hour ago"
```

### Stop/Disable Service
```bash
sudo systemctl stop grist-payment-updater.timer
sudo systemctl disable grist-payment-updater.timer
```

## Development

### Dependencies
- Python 3.12+
- `httpx` - HTTP client
- `python-dateutil` - Date manipulation
- `python-dotenv` - Environment file loading

### Local Testing with Nix
```bash
nix-shell -p python3 python3Packages.httpx python3Packages.python-dateutil python3Packages.python-dotenv \
  --run "python3 main.py"
```

### Project Structure
```
grist-payment-updater/
├── main.py          # Main application
├── service.nix      # NixOS service definition  
├── pyproject.toml   # Python dependencies
├── README.md        # This file
└── CLAUDE.md        # AI assistant context
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: 
   - Verify API key is correct
   - Check Authelia proxy settings

2. **No Records Updated**:
   - Check field names match (`Next_Payment`, `Recurrence`)
   - Verify recurrence values are exact: `Yearly`, `Monthly`, `Two weeks`

3. **Service Won't Start**:
   - Check environment file permissions: `sudo ls -la /etc/grist-payment-updater/`
   - Verify user exists: `id grist-updater`

### Debug Mode
Enable detailed logging by modifying `main.py`:
```python
logging.basicConfig(level=logging.DEBUG)
```

## Security Notes

- API key stored in `/etc/grist-payment-updater/env` with restricted permissions
- Service runs as dedicated `grist-updater` user (not root)
- Authelia proxy provides additional authentication layer
- Dry-run mode enabled by default prevents accidental changes