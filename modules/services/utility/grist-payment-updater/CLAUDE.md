# Claude AI Assistant Context

This file contains information for AI assistants working on this project.

## Project Location

This project is located in Jeremy's dotfiles repository at:
- **Path**: `~/dotfiles/modules/services/utility/grist-payment-updater/`
- **Repository**: Personal NixOS/home-manager configuration dotfiles
- **Integration**: Part of NixOS system configuration in `hosts/navi/services.nix`

## Project Overview

**Grist Payment Date Updater** is a Python daemon that automatically updates payment due dates in a Grist spreadsheet based on recurrence patterns. It prevents missed payments by advancing past dates to future occurrences.

## Key Technical Details

### Architecture
- **Language**: Python 3.12+ with uv package management
- **HTTP Client**: httpx for async-capable requests
- **Date Handling**: python-dateutil for robust date arithmetic
- **Deployment**: NixOS systemd service with daily timer
- **Security**: Dedicated user account, environment files, Authelia proxy auth

### Grist Integration
- **API Authentication**: Bearer token + Authelia proxy headers
- **Document URL**: `https://grist.jeremyk.net/iDEabeoAf4nC/Finances`
- **Table**: `Data` (main financial records table)
- **Key Fields**:
  - `Next_Payment` (Unix timestamp)
  - `Recurrence` (text: "Yearly", "Monthly", "Two weeks")

### Date Logic
The core algorithm advances payment dates to the next future occurrence:
```python
while date.date() <= today:
    if recurrence == 'yearly': date += relativedelta(years=1)
    elif recurrence == 'monthly': date += relativedelta(months=1)  
    elif recurrence == 'two weeks': date += timedelta(weeks=2)
```

### Safety Features
- **Dry-run mode**: Default behavior, prevents accidental changes
- **Detailed logging**: Shows exactly what would change before execution
- **Type-safe date handling**: Handles both string and timestamp formats
- **Error recovery**: Graceful handling of missing/invalid data

## Development Guidelines

### When modifying this project:

1. **Always test in dry-run mode first** - Never skip the safety check
2. **Preserve the date calculation logic** - It correctly handles edge cases
3. **Maintain NixOS compatibility** - Use only packages available in nixpkgs
4. **Keep security practices** - Dedicated user, restricted permissions
5. **Update both README.md and CLAUDE.md** when making changes

### Common Tasks

**Adding new recurrence types**:
```python
elif recurrence.lower() == 'quarterly':
    date += relativedelta(months=3)
```

**Changing field names**:
Update the field references in `process_records()`:
```python
current_payment_date = fields.get('Your_Field_Name')
```

**Testing changes**:
```bash
nix-shell -p python3 python3Packages.httpx python3Packages.python-dateutil \
  --run "python3 main.py"  # Always runs dry-run first
```

## Production Environment

### Service Configuration
- **Runtime**: Daily at 8:00 AM via systemd timer
- **User**: `grist-updater` (system user, non-root)
- **Environment**: `/etc/grist-payment-updater/env`
- **Logs**: Available via `journalctl -u grist-payment-updater.service`

### Monitoring
- Check timer status: `systemctl list-timers grist-payment-updater*`
- View recent execution: `journalctl -u grist-payment-updater.service --since "24 hours ago"`
- Manual execution: `sudo systemctl start grist-payment-updater.service`

## Dependencies

### Runtime Dependencies
```toml
dependencies = [
    "httpx>=0.25.0",        # HTTP client with async support
    "python-dateutil>=2.8.0", # Robust date arithmetic
    "python-dotenv>=1.0.0", # Environment file loading for standalone use
]
```

### NixOS Integration
The service.nix provides complete systemd integration:
- Service definition with proper user/group
- Daily timer at exactly 8:00 AM
- Environment file management
- Proper file permissions and security

### Running Python Scripts
For standalone development and testing:
```bash
# Use nix-shell with required packages
nix-shell -p python3 python3Packages.httpx python3Packages.python-dateutil python3Packages.python-dotenv \
  --run "python3 main.py"

# Or enter the shell and run commands
nix-shell -p python3 python3Packages.httpx python3Packages.python-dateutil python3Packages.python-dotenv
python3 main.py
```

The script automatically loads `.env` file for standalone use via python-dotenv.

## API Details

### Authentication Headers
```python
headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json", 
    "Proxy-Authorization": proxy_auth  # From environment variable
}
```

### Endpoints Used
- `GET /api/docs/{doc_id}/tables` - List available tables
- `GET /api/docs/{doc_id}/tables/{table}/records` - Fetch records
- `PATCH /api/docs/{doc_id}/tables/{table}/records` - Update records

## Error Handling

The application handles these scenarios gracefully:
- Missing API key or invalid authentication
- Network timeouts or connection issues  
- Missing or malformed date/recurrence fields
- Grist API errors or rate limiting
- Invalid date formats or calculation errors

## Testing Strategy

1. **Dry-run validation**: Always run without `DRY_RUN=false` first
2. **Small batch testing**: Test with limited records if possible
3. **Log analysis**: Verify proposed changes before live execution
4. **Rollback plan**: Grist maintains revision history for recovery

## Maintenance Notes

- **API key rotation**: Update in `/etc/grist-payment-updater/env`
- **Schema changes**: Update field names in `main.py` if Grist table structure changes
- **Timezone considerations**: Service runs in system timezone, dates are UTC-aware
- **Performance**: Processes ~50 records efficiently, scales well for larger datasets