"""Centralized host mapping and configuration."""

from typing import Dict, NamedTuple


class HostConfig(NamedTuple):
    """Configuration for a single host."""
    name: str
    color: str
    ip_addresses: list[str]
    domains: list[str]


# Centralized host mapping configuration
HOST_CONFIGS = {
    "bee": HostConfig(
        name="bee",
        color="blue",
        ip_addresses=["192.168.1.245", "100.74.102.74"],
        domains=["bee.sole-bigeye.ts.net"]
    ),
    "navi": HostConfig(
        name="navi",
        color="cyan",
        ip_addresses=["192.168.1.250", "100.75.187.40"],
        domains=["navi.sole-bigeye.ts.net"]
    ),
    "tower": HostConfig(
        name="tower", 
        color="yellow",
        ip_addresses=["192.168.1.240", "100.115.172.123"],
        domains=["tower.sole-bigeye.ts.net"]
    ),
    "halo": HostConfig(
        name="halo",
        color="magenta", 
        ip_addresses=["100.78.79.103", "46.62.144.212"],
        domains=["halo.sole-bigeye.ts.net"]
    ),
    "pi": HostConfig(
        name="pi",
        color="green",
        ip_addresses=["192.168.1.230", "100.124.210.114"], 
        domains=["pi.sole-bigeye.ts.net"]
    )
}


def get_host_mapping() -> Dict[str, str]:
    """Get the host mapping dictionary for URL host resolution.
    
    Returns:
        Dictionary mapping IP addresses and domains to friendly host names
    """
    mapping = {
        "localhost": "bee",  # Localhost services run on bee
    }
    
    # Add all IP addresses and domains for each host
    for host_config in HOST_CONFIGS.values():
        for ip in host_config.ip_addresses:
            mapping[ip] = host_config.name
        for domain in host_config.domains:
            mapping[domain] = host_config.name
    
    return mapping


def get_host_color(host_name: str) -> str:
    """Get the color for a host.
    
    Args:
        host_name: Name of the host
        
    Returns:
        Color name for the host, or "white" if not found
    """
    if host_name in HOST_CONFIGS:
        return HOST_CONFIGS[host_name].color
    return "white"


def get_all_host_names() -> list[str]:
    """Get list of all configured host names.
    
    Returns:
        List of host names
    """
    return list(HOST_CONFIGS.keys())