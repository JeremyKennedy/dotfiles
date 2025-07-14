"""Traefik API integration for service discovery."""

import json
from typing import Dict, List
import httpx
from dataclasses import dataclass


@dataclass
class TraefikService:
    """Represents a service discovered from Traefik configuration."""

    name: str
    backend_url: str
    frontend_domain: str
    routing_type: str = "Direct"
    custom_path: str = ""


class TraefikClient:
    """Client for interacting with Traefik API."""

    def __init__(self, api_url: str = "http://100.74.102.74:9090"):
        """Initialize Traefik client.

        Args:
            api_url: Base URL for Traefik API
        """
        self.api_url = api_url.rstrip("/")
        self.timeout = 30.0

    async def get_services(self, service_paths: Dict[str, str] = None) -> List[TraefikService]:
        """Extract all services from Traefik configuration.

        This method replicates the bash script's logic for discovering services
        from the NixOS configuration via Traefik API.

        Returns:
            List of TraefikService objects
        """
        try:
            # Get services from NixOS configuration (similar to bash script)
            services = await self._get_nix_services()

            # Get router information from Traefik API
            routers = await self._get_traefik_routers()

            # Combine service and router information
            traefik_services = []
            if service_paths is None:
                service_paths = {}
                
            for service_name, backend_url in services.items():
                frontend_domain = self._get_frontend_domain(service_name, routers)
                routing_type = self._determine_routing_type(backend_url)
                custom_path = service_paths.get(service_name, "")

                traefik_services.append(
                    TraefikService(
                        name=service_name,
                        backend_url=backend_url,
                        frontend_domain=frontend_domain,
                        routing_type=routing_type,
                        custom_path=custom_path,
                    )
                )

            return sorted(traefik_services, key=lambda x: x.name)

        except Exception as e:
            raise RuntimeError(f"Failed to discover Traefik services: {e}")

    async def _get_nix_services(self) -> Dict[str, str]:
        """Get services from NixOS configuration.

        This replicates the bash script's nix eval command:
        nix eval .#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions.http.services --json
        """
        import asyncio

        try:
            # Run nix eval command to get Traefik services
            cmd = [
                "nix",
                "eval",
                ".#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions.http.services",
                "--json",
            ]

            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd="/home/jeremy/dotfiles",  # Must run from repo root
            )

            stdout, stderr = await asyncio.wait_for(
                process.communicate(), timeout=self.timeout
            )

            if process.returncode != 0:
                raise RuntimeError(f"nix eval failed: {stderr.decode()}")

            services_config = json.loads(stdout.decode())

            # Extract service name and backend URL from configuration
            services = {}
            for service_name, config in services_config.items():
                if "loadBalancer" in config and "servers" in config["loadBalancer"]:
                    servers = config["loadBalancer"]["servers"]
                    if servers and "url" in servers[0]:
                        services[service_name] = servers[0]["url"]

            return services

        except asyncio.TimeoutError:
            raise RuntimeError("Timeout getting NixOS Traefik configuration")
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Failed to parse NixOS configuration JSON: {e}")
        except Exception as e:
            raise RuntimeError(f"Failed to get NixOS services: {e}")

    async def _get_traefik_routers(self) -> Dict[str, str]:
        """Get router configuration from Traefik API.

        Returns:
            Dictionary mapping service names to their router rules
        """
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.api_url}/api/http/routers")
                response.raise_for_status()

                routers = response.json()

                # Map service names to their Host() rules
                service_rules = {}
                for router in routers:
                    if "service" in router and "rule" in router:
                        service_rules[router["service"]] = router["rule"]

                return service_rules

        except httpx.TimeoutException:
            raise RuntimeError("Timeout connecting to Traefik API")
        except httpx.HTTPStatusError as e:
            raise RuntimeError(
                f"Traefik API error {e.response.status_code}: {e.response.text}"
            )
        except Exception as e:
            raise RuntimeError(f"Failed to get Traefik routers: {e}")

    def _get_frontend_domain(self, service_name: str, routers: Dict[str, str]) -> str:
        """Extract frontend domain from router rules.

        Args:
            service_name: Name of the service
            routers: Dictionary of router rules

        Returns:
            Frontend domain URL for the service
        """
        if service_name in routers:
            rule = routers[service_name]
            # Extract first Host() from rule - this is the primary domain
            import re

            match = re.search(r"Host\(`([^`]+)`\)", rule)
            if match:
                domain = match.group(1)
                return f"https://{domain}"

        # Fallback to building URL from service name
        return f"https://{service_name}.home.jeremyk.net"

    def _determine_routing_type(self, backend_url: str) -> str:
        """Determine the routing type based on backend URL.

        Args:
            backend_url: Backend URL from Traefik configuration

        Returns:
            Host-based routing type string (e.g., "tower", "bee", "tower-swag")
        """
        # Extract host from URL
        host = self._extract_host_from_url(backend_url)

        # Special case for SWAG proxy on Tower
        if ":18071" in backend_url:
            return f"{host}-swag"

        # All other services just use the host name
        return host

    def _extract_host_from_url(self, url: str) -> str:
        """Extract and map host from backend URL to friendly name.

        Args:
            url: Backend URL (e.g., "http://192.168.1.240:8080/")

        Returns:
            Friendly host name (e.g., "tower", "bee", "halo")
        """
        import re

        # Extract hostname/IP from URL
        match = re.search(r"https?://([^:/]+)", url)
        if not match:
            return "unknown"

        host = match.group(1)

        # Map to friendly names
        host_mapping = {
            "192.168.1.245": "bee",
            "100.74.102.74": "bee",  # TS bee IP
            "bee.sole-bigeye.ts.net": "bee",
            "localhost": "bee",  # Localhost services run on bee
            "192.168.1.240": "tower",
            "tower.sole-bigeye.ts.net": "tower",
            "halo.sole-bigeye.ts.net": "halo",
            "pi.sole-bigeye.ts.net": "pi",
        }

        return host_mapping.get(host, host)  # Return original if not mapped
