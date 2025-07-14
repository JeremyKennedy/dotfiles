"""Infrastructure testing for network connectivity, DNS, and core services."""

import asyncio
import re
from dataclasses import dataclass
from typing import Dict, List, Optional
import httpx


@dataclass
class PingTestResult:
    """Result of a ping connectivity test."""

    name: str
    target: str
    success: bool = False
    response_time: Optional[float] = None
    error_message: str = ""
    skipped: bool = False
    skip_reason: str = ""


@dataclass
class DNSTestResult:
    """Result of a DNS resolution test."""

    name: str
    query: str
    nameserver: Optional[str] = None
    success: bool = False
    resolved_ips: List[str] = None
    response_time: Optional[float] = None
    error_message: str = ""

    def __post_init__(self):
        if self.resolved_ips is None:
            self.resolved_ips = []


@dataclass
class InfrastructureTestResult:
    """Combined result of infrastructure tests."""

    ping_results: List[PingTestResult] = None
    dns_results: List[DNSTestResult] = None
    direct_service_results: List = None  # ServiceTestResult objects

    def __post_init__(self):
        if self.ping_results is None:
            self.ping_results = []
        if self.dns_results is None:
            self.dns_results = []
        if self.direct_service_results is None:
            self.direct_service_results = []


class InfrastructureTester:
    """Test core infrastructure components."""

    def __init__(self, timeout: float = 5.0):
        """Initialize infrastructure tester.

        Args:
            timeout: Default timeout for tests in seconds
        """
        self.timeout = timeout

    async def test_all_infrastructure(self, config) -> InfrastructureTestResult:
        """Run comprehensive infrastructure tests.

        This replicates the bash script's test_infrastructure function.

        Args:
            config: HomelabTestConfig object with hosts and services

        Returns:
            InfrastructureTestResult with all test results
        """
        # Run all infrastructure tests concurrently
        ping_task = self.test_network_connectivity(config.hosts)
        dns_task = self.test_dns_resolution(config.dns_tests)
        services_task = self.test_direct_services(config.direct_services)

        ping_results, dns_results, service_results = await asyncio.gather(
            ping_task, dns_task, services_task
        )

        return InfrastructureTestResult(
            ping_results=ping_results,
            dns_results=dns_results,
            direct_service_results=service_results,
        )

    async def test_network_connectivity(self, hosts: List) -> List[PingTestResult]:
        """Test network connectivity with ping tests.

        Args:
            hosts: List of HostConfig objects from configuration

        Returns:
            List of PingTestResult objects
        """
        ping_tests = []
        for host in hosts:
            ping_tests.append(
                PingTestResult(
                    host.name,
                    host.ip_address,
                    skipped=host.skip_ping,
                    skip_reason=host.skip_reason,
                )
            )

            # Add Tailscale test if hostname provided
            if host.tailscale_hostname:
                ping_tests.append(
                    PingTestResult(f"{host.name} TS", host.tailscale_hostname)
                )

        # Run ping tests concurrently
        tasks = [self._ping_test(test) for test in ping_tests if not test.skipped]
        results = await asyncio.gather(*tasks)

        # Add skipped tests back to results
        skipped_tests = [test for test in ping_tests if test.skipped]
        return results + skipped_tests

    async def _ping_test(self, test: PingTestResult) -> PingTestResult:
        """Execute a single ping test.

        Args:
            test: PingTestResult object with target information

        Returns:
            Updated PingTestResult with test results
        """
        try:
            process = await asyncio.create_subprocess_exec(
                "ping",
                "-c",
                "1",
                "-W",
                "3",
                test.target,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )

            stdout, stderr = await asyncio.wait_for(
                process.communicate(), timeout=self.timeout
            )

            if process.returncode == 0:
                test.success = True
                # Extract ping time from output if available
                output = stdout.decode()
                time_match = re.search(r"time=(\d+\.?\d*)", output)
                if time_match:
                    test.response_time = float(time_match.group(1))
            else:
                test.success = False
                test.error_message = "Unreachable"

        except asyncio.TimeoutError:
            test.success = False
            test.error_message = "Timeout"
        except Exception as e:
            test.success = False
            test.error_message = f"Error: {str(e)}"

        return test

    async def test_dns_resolution(self, dns_tests: List) -> List[DNSTestResult]:
        """Test DNS resolution functionality.

        Args:
            dns_tests: List of DNSTestConfig objects from configuration

        Returns:
            List of DNSTestResult objects
        """
        test_objects = []
        for test_config in dns_tests:
            test_objects.append(
                DNSTestResult(
                    name=test_config.name,
                    query=test_config.query,
                    nameserver=(
                        test_config.nameserver if test_config.nameserver else None
                    ),
                )
            )

        # Run DNS tests concurrently
        tasks = [self._dns_test(test) for test in test_objects]
        return await asyncio.gather(*tasks)

    async def _dns_test(self, test: DNSTestResult) -> DNSTestResult:
        """Execute a single DNS resolution test.

        Args:
            test: DNSTestResult object with query information

        Returns:
            Updated DNSTestResult with test results
        """
        try:
            # Build dig command
            cmd = ["dig", test.query, "+short", "+timeout=3"]
            if test.nameserver:
                cmd.extend([f"@{test.nameserver}"])

            process = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )

            stdout, stderr = await asyncio.wait_for(
                process.communicate(), timeout=self.timeout
            )

            if process.returncode == 0:
                output = stdout.decode().strip()
                if output:
                    # Parse resolved IPs
                    lines = output.split("\n")
                    ip_pattern = re.compile(r"^\d+\.\d+\.\d+\.\d+$")
                    ips = [
                        line.strip() for line in lines if ip_pattern.match(line.strip())
                    ]

                    if ips:
                        test.success = True
                        test.resolved_ips = ips
                    else:
                        test.success = False
                        test.error_message = "No IP addresses resolved"
                else:
                    test.success = False
                    test.error_message = "Empty response"
            else:
                test.success = False
                test.error_message = "DNS query failed"

        except asyncio.TimeoutError:
            test.success = False
            test.error_message = "Timeout"
        except Exception as e:
            test.success = False
            test.error_message = f"Error: {str(e)}"

        return test

    async def test_direct_services(self, direct_services: List) -> List:
        """Test direct infrastructure services (bypassing Traefik).

        Args:
            direct_services: List of DirectServiceConfig objects from configuration

        Returns:
            List of ServiceTestResult objects from direct service tests
        """
        # Import here to avoid circular imports
        from .services import ServiceTestResult

        services = [
            (service.name, service.url, service.routing_type)
            for service in direct_services
        ]

        results = []
        for service_name, url, routing_type in services:
            try:
                start_time = asyncio.get_event_loop().time()

                async with httpx.AsyncClient(
                    timeout=self.timeout, follow_redirects=True, verify=False
                ) as client:
                    response = await client.get(url)

                    response_time = asyncio.get_event_loop().time() - start_time

                    result = ServiceTestResult(
                        service_name=service_name,
                        url=url,
                        routing_type=routing_type,
                        status_code=response.status_code,
                        response_size=len(response.content),
                        response_time=response_time,
                        redirect_count=len(response.history),
                        success=200 <= response.status_code < 400,
                    )

                    if not result.success:
                        result.error_message = f"HTTP {response.status_code}"

                    results.append(result)

            except httpx.TimeoutException:
                results.append(
                    ServiceTestResult(
                        service_name=service_name,
                        url=url,
                        routing_type=routing_type,
                        error_message="Connection timeout",
                    )
                )
            except Exception as e:
                results.append(
                    ServiceTestResult(
                        service_name=service_name,
                        url=url,
                        routing_type=routing_type,
                        error_message=f"Error: {str(e)}",
                    )
                )

        return results


class NetworkAnalyzer:
    """Analyze network layer issues based on test results."""

    def analyze_network_layers(
        self, infrastructure_result: InfrastructureTestResult
    ) -> Dict[str, any]:
        """Analyze network layers for potential issues.

        This replicates the bash script's network analysis logic.

        Args:
            infrastructure_result: Combined infrastructure test results

        Returns:
            Dictionary with network analysis results
        """
        analysis = {"network_healthy": True, "issues": [], "recommendations": []}

        # Check router connectivity
        router_ping = next(
            (
                r
                for r in infrastructure_result.ping_results
                if "192.168.1.1" in r.target
            ),
            None,
        )
        if router_ping and not router_ping.success:
            analysis["network_healthy"] = False
            analysis["issues"].append("LAN issues detected (router unreachable)")
            analysis["recommendations"].append(
                "Check local network connection and router status"
            )

        # Check internet connectivity
        internet_ping = next(
            (r for r in infrastructure_result.ping_results if "8.8.8.8" in r.target),
            None,
        )
        if internet_ping and not internet_ping.success:
            analysis["network_healthy"] = False
            analysis["issues"].append("WAN issues detected (internet unreachable)")
            analysis["recommendations"].append(
                "Check internet connection and ISP status"
            )

        # Check internal DNS
        internal_dns = next(
            (
                r
                for r in infrastructure_result.dns_results
                if "hass.home.jeremyk.net" in r.query
            ),
            None,
        )
        if internal_dns and not internal_dns.success:
            analysis["network_healthy"] = False
            analysis["issues"].append(
                "DNS issues detected (internal resolution failing)"
            )
            analysis["recommendations"].append(
                "Check Bee DNS services (CoreDNS/AdGuard)"
            )

        # Analyze service failures
        failed_services = [
            r for r in infrastructure_result.direct_service_results if not r.success
        ]
        if len(failed_services) > 2:
            analysis["network_healthy"] = False
            analysis["issues"].append("Multiple service failures detected")
            analysis["recommendations"].append(
                "Check Tailscale connectivity and service containers"
            )

        return analysis
