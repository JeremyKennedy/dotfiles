# CLAUDE.md - Homelab Test Framework

This file provides context for AI assistants working on the homelab testing framework.

## Project Overview

**Homelab Test Framework** is a modern Python-based replacement for the bash `test-services.sh` script. It provides comprehensive testing of homelab services with better performance, structure, and reporting.

## Key Features

### Architecture
- **Language**: Python 3.8+ with uv package management
- **Testing**: pytest with async support and rich reporting
- **HTTP Client**: httpx for async HTTP requests (replaces curl)
- **Console Output**: rich library for beautiful terminal output
- **Configuration**: TOML-based configuration system
- **Parallel Execution**: Concurrent testing for better performance

### Core Components

#### Service Discovery (`traefik.py`)
- Integrates with Traefik API to discover services
- Extracts service configuration from NixOS using `nix eval`
- Maps backend URLs to frontend domains
- Categorizes services by routing type (Direct, SWAG, Infrastructure)

#### Service Testing (`services.py`)
- Async HTTP testing with detailed response analysis
- Preserves all bash script logic for error detection
- Special handling for Plex redirects and other edge cases
- Concurrent testing for improved performance
- Rich metrics collection (response time, size, redirects)

#### Infrastructure Testing (`infrastructure.py`)
- Network connectivity tests (ping)
- DNS resolution tests
- Direct service tests (bypassing Traefik)
- Network layer analysis and recommendations

#### Reporting (`reporting.py`)
- Rich console output with colors, tables, and progress bars
- JSON export for integration with monitoring systems
- Health score calculation and categorization
- Detailed failure analysis and recommendations

#### Configuration (`config.py`)
- TOML-based configuration with sensible defaults
- Configurable timeouts, hosts, and services
- Override capability for different environments

## Usage

### Basic Commands
```bash
# Install dependencies (from homelab-test directory)
uv sync

# Run full health check
uv run homelab-test

# Test infrastructure only
uv run homelab-test --infrastructure

# Discover Traefik services only
uv run homelab-test --discover

# JSON output for automation
uv run homelab-test --output json

# Export detailed report
uv run homelab-test --export-json report.json
```

### Integration with justfile
```bash
# From repo root (/home/jeremy/dotfiles)
just test-services          # Run homelab test framework
just test-services-legacy   # Run original bash script
```

### Configuration
The framework uses `config.toml` for configuration. Create default config:
```bash
uv run homelab-test --create-config
```

## Development

### Project Structure
```
scripts/homelab-test/
├── pyproject.toml              # uv project configuration
├── config.toml                 # Default configuration
├── src/homelab_test/
│   ├── __init__.py
│   ├── cli.py                  # Command-line interface
│   ├── config.py               # Configuration management
│   ├── traefik.py              # Traefik API integration
│   ├── services.py             # Service testing
│   ├── infrastructure.py       # Infrastructure testing
│   └── reporting.py            # Console reporting
├── tests/
│   ├── conftest.py             # pytest configuration
│   ├── test_infrastructure.py  # Infrastructure tests
│   ├── test_traefik_services.py # Traefik/service tests
│   └── test_direct_services.py # Direct service tests
└── CLAUDE.md                   # This documentation
```

### Running Tests
```bash
# Run all tests
uv run pytest

# Run specific test categories
uv run pytest -m infrastructure
uv run pytest -m services
uv run pytest -m integration

# Run with coverage
uv run pytest --cov=homelab_test

# Run tests in parallel
uv run pytest -n auto
```

### Key Dependencies
- **httpx**: Async HTTP client (replaces curl)
- **pytest**: Testing framework with async support
- **rich**: Terminal formatting and progress bars
- **python-dateutil**: Date/time handling
- **tomli/tomllib**: TOML configuration parsing

## Migration from Bash Script

### Preserved Functionality
All functionality from the original `test-services.sh` has been preserved:

1. **Service Discovery**: Uses same `nix eval` command to extract Traefik services
2. **Error Analysis**: Preserves detailed error categorization logic
3. **Response Analysis**: Maintains special cases (Plex redirects, etc.)
4. **Network Analysis**: Same ping, DNS, and connectivity tests
5. **Health Scoring**: Identical health score calculation
6. **Categorization**: Same service categorization (Direct, SWAG, Infrastructure)

### Improvements
1. **Performance**: Parallel execution vs sequential bash
2. **Output**: Rich console formatting vs basic color codes
3. **Configuration**: TOML config vs hardcoded values
4. **Testing**: Comprehensive test suite vs manual testing
5. **Maintainability**: Python modules vs monolithic bash script
6. **Extensibility**: Easy to add new test types and outputs

### Compatibility
- Exit codes: Maintains same exit code behavior (0 = success, 1 = failures)
- Output format: Can output JSON for automation compatibility
- Remote testing: Supports SSH remote testing (via CLI args)

## Integration Notes

### NixOS Integration
The framework runs from the repository root and expects:
- Access to `nix eval` command for service discovery
- Tailscale connectivity for service testing
- Standard homelab network configuration

### Security Considerations
- No secrets in code (follows existing patterns)
- Tailscale-only access for internal services
- SSL verification disabled for internal services (like bash script)
- Safe error handling prevents credential exposure

### Monitoring Integration
- JSON output format for CI/monitoring systems
- Detailed metrics for performance monitoring
- Health scores for alerting thresholds
- Export capability for long-term analysis

## Common Tasks

### Adding New Services
Edit `config.toml` to add direct services:
```toml
[[direct_services]]
name = "new-service"
url = "http://host:port"
routing_type = "Infrastructure"
```

### Customizing Timeouts
```toml
[timeouts]
default = 5.0
infrastructure = 15.0
```

### Adding New Hosts
```toml
[[hosts]]
name = "New Host"
ip_address = "192.168.1.100"
tailscale_hostname = "newhost.sole-bigeye.ts.net"
```

### Debugging Issues
```bash
# Verbose output
uv run homelab-test --verbose

# Test specific component
uv run homelab-test --infrastructure
uv run homelab-test --discover

# Export for analysis
uv run homelab-test --export-json debug.json
```

## Performance Characteristics

### Typical Execution Times
- Infrastructure tests: 5-10 seconds
- Service discovery: 2-5 seconds  
- Service testing (parallel): 10-20 seconds
- Total runtime: 20-35 seconds (vs 60-90 seconds for bash)

### Resource Usage
- Memory: ~50MB peak (Python + dependencies)
- CPU: Moderate during parallel HTTP requests
- Network: Similar to bash script (same requests made)

## Future Enhancements

Potential improvements for future development:
1. **Prometheus Metrics**: Export metrics to Prometheus
2. **Web Dashboard**: Simple web interface for results
3. **Historical Tracking**: Store results over time
4. **Alerting**: Integration with notification systems
5. **Service Dependencies**: Test order based on dependencies
6. **Custom Checks**: Plugin system for service-specific health checks

## Maintenance

### Updating Dependencies
```bash
uv lock --upgrade
uv sync
```

### Adding New Test Types
1. Add test logic to appropriate module
2. Update configuration schema if needed
3. Add tests in `tests/` directory
4. Update CLI interface if new options needed

### Troubleshooting
- **Import errors**: Ensure `uv sync` has been run
- **Network timeouts**: Check Tailscale connectivity
- **Service discovery fails**: Verify `nix eval` works from repo root
- **Tests fail**: Run with `--verbose` for detailed error information