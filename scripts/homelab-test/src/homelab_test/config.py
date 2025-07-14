"""Configuration management for homelab testing."""

import sys
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field

# Handle tomli import for Python < 3.11
if sys.version_info >= (3, 11):
    import tomllib
else:
    try:
        import tomli as tomllib
    except ImportError:
        raise ImportError("tomli package is required for Python < 3.11")


@dataclass
class TimeoutConfig:
    """Timeout configuration for different test types."""

    default: float = 5.0
    ping: float = 3.0
    dns: float = 5.0
    http: float = 5.0
    infrastructure: float = 10.0


@dataclass
class TraefikConfig:
    """Traefik API configuration."""

    api_url: str = "http://100.74.102.74:9090"
    timeout: float = 30.0


@dataclass
class HostConfig:
    """Host configuration for testing."""

    name: str
    ip_address: str
    tailscale_hostname: str = ""
    skip_ping: bool = False
    skip_reason: str = ""


@dataclass
class DirectServiceConfig:
    """Direct service configuration."""

    name: str
    url: str
    routing_type: Optional[str] = None
    timeout: Optional[float] = None


@dataclass
class DNSTestConfig:
    """DNS test configuration."""

    name: str
    query: str
    nameserver: str = ""


@dataclass
class HomelabTestConfig:
    """Main configuration for homelab testing."""

    timeouts: TimeoutConfig = field(default_factory=TimeoutConfig)
    traefik: TraefikConfig = field(default_factory=TraefikConfig)
    hosts: List[HostConfig] = field(default_factory=list)
    direct_services: List[DirectServiceConfig] = field(default_factory=list)
    dns_tests: List[DNSTestConfig] = field(default_factory=list)
    traefik_paths: Dict[str, str] = field(default_factory=dict)
    domain_suffix: str = "home.jeremyk.net"
    output_format: str = "rich"  # rich, json, plain
    parallel_execution: bool = True
    follow_redirects: bool = True
    verify_ssl: bool = False


class ConfigManager:
    """Configuration manager for homelab testing."""

    def __init__(self, config_path: Optional[Path] = None):
        """Initialize configuration manager.

        Args:
            config_path: Path to configuration file, uses default if None
        """
        self.config_path = config_path or self._get_default_config_path()
        self._config: Optional[HomelabTestConfig] = None

    def _get_default_config_path(self) -> Path:
        """Get default configuration file path."""
        # Look for config in these locations (in order):
        # 1. Current directory
        # 2. Script directory
        # 3. User config directory

        script_dir = Path(__file__).parent.parent.parent

        search_paths = [
            Path.cwd() / "config.toml",
            script_dir / "config.toml",
            Path.home() / ".config" / "homelab-test" / "config.toml",
        ]

        for path in search_paths:
            if path.exists():
                return path

        # Return first path as default (will be created if needed)
        return search_paths[0]

    def load_config(self) -> HomelabTestConfig:
        """Load configuration from file or create default.

        Returns:
            HomelabTestConfig instance
        """
        if self._config is not None:
            return self._config

        if self.config_path.exists():
            self._config = self._load_from_file()
        else:
            raise ConfigError(
                f"Configuration file not found: {self.config_path}. Copy config.toml to this location."
            )

        return self._config

    def _load_from_file(self) -> HomelabTestConfig:
        """Load configuration from TOML file.

        Returns:
            HomelabTestConfig instance

        Raises:
            ConfigError: If configuration file is invalid
        """
        try:
            with open(self.config_path, "rb") as f:
                data = tomllib.load(f)

            return self._parse_config_data(data)

        except tomllib.TOMLDecodeError as e:
            raise ConfigError(f"Invalid TOML syntax in {self.config_path}: {e}")
        except FileNotFoundError:
            raise ConfigError(f"Configuration file not found: {self.config_path}")
        except Exception as e:
            raise ConfigError(f"Error loading configuration: {e}")

    def _parse_config_data(self, data: Dict[str, Any]) -> HomelabTestConfig:
        """Parse configuration data from TOML.

        Args:
            data: Parsed TOML data

        Returns:
            HomelabTestConfig instance
        """
        config = HomelabTestConfig()

        # Parse timeouts section
        if "timeouts" in data:
            timeouts_data = data["timeouts"]
            config.timeouts = TimeoutConfig(
                default=timeouts_data.get("default", config.timeouts.default),
                ping=timeouts_data.get("ping", config.timeouts.ping),
                dns=timeouts_data.get("dns", config.timeouts.dns),
                http=timeouts_data.get("http", config.timeouts.http),
                infrastructure=timeouts_data.get(
                    "infrastructure", config.timeouts.infrastructure
                ),
            )

        # Parse traefik section
        if "traefik" in data:
            traefik_data = data["traefik"]
            config.traefik = TraefikConfig(
                api_url=traefik_data.get("api_url", config.traefik.api_url),
                timeout=traefik_data.get("timeout", config.traefik.timeout),
            )

        # Parse hosts section
        if "hosts" in data:
            config.hosts = []
            for host_data in data["hosts"]:
                config.hosts.append(
                    HostConfig(
                        name=host_data["name"],
                        ip_address=host_data["ip_address"],
                        tailscale_hostname=host_data.get("tailscale_hostname", ""),
                        skip_ping=host_data.get("skip_ping", False),
                        skip_reason=host_data.get("skip_reason", ""),
                    )
                )

        # Parse direct_services section
        if "direct_services" in data:
            config.direct_services = []
            for service_data in data["direct_services"]:
                routing_type = service_data.get("routing_type")
                if routing_type is None:
                    # Auto-infer routing type from URL
                    routing_type = self._infer_routing_type_from_url(service_data["url"])
                
                config.direct_services.append(
                    DirectServiceConfig(
                        name=service_data["name"],
                        url=service_data["url"],
                        routing_type=routing_type,
                        timeout=service_data.get("timeout"),
                    )
                )

        # Parse dns_tests section
        if "dns_tests" in data:
            config.dns_tests = []
            for dns_data in data["dns_tests"]:
                config.dns_tests.append(
                    DNSTestConfig(
                        name=dns_data["name"],
                        query=dns_data["query"],
                        nameserver=dns_data.get("nameserver", ""),
                    )
                )

        # Parse traefik_paths section
        if "traefik_paths" in data:
            config.traefik_paths = data["traefik_paths"]

        # Parse general settings
        config.domain_suffix = data.get("domain_suffix", config.domain_suffix)
        config.output_format = data.get("output_format", config.output_format)
        config.parallel_execution = data.get(
            "parallel_execution", config.parallel_execution
        )
        config.follow_redirects = data.get("follow_redirects", config.follow_redirects)
        config.verify_ssl = data.get("verify_ssl", config.verify_ssl)

        return config

    def _infer_routing_type_from_url(self, url: str) -> str:
        """Infer routing type from URL using same logic as Traefik client.
        
        Args:
            url: Service URL to analyze
            
        Returns:
            Inferred routing type (host-based)
        """
        import re
        
        # Extract hostname/IP from URL
        match = re.search(r"https?://([^:/]+)", url)
        if not match:
            return "unknown"
            
        host = match.group(1)
        
        # Map to friendly names (same as TraefikClient)
        host_mapping = {
            "192.168.1.240": "tower",
            "192.168.1.245": "bee", 
            "100.74.102.74": "bee",  # TS bee IP
            "bee.sole-bigeye.ts.net": "bee",
            "tower.sole-bigeye.ts.net": "tower",
            "halo.sole-bigeye.ts.net": "halo",
            "pi.sole-bigeye.ts.net": "pi",
            "localhost": "bee",  # Localhost services run on bee
        }
        
        # Check for SWAG proxy port
        if ":18071" in url:
            mapped_host = host_mapping.get(host, host)
            return f"{mapped_host}-swag"
        
        return host_mapping.get(host, host)


class ConfigError(Exception):
    """Configuration-related error."""

    pass


def get_config(config_path: Optional[Path] = None) -> HomelabTestConfig:
    """Get configuration instance.

    Args:
        config_path: Path to configuration file

    Returns:
        HomelabTestConfig instance
    """
    manager = ConfigManager(config_path)
    return manager.load_config()
