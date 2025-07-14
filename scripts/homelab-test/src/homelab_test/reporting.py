"""Rich console reporting for beautiful test output."""

from typing import List, Dict
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import (
    Progress,
    SpinnerColumn,
    TextColumn,
    BarColumn,
    TimeElapsedColumn,
)
from rich.text import Text
from datetime import datetime

from .services import ServiceTestResult, ServiceTestReporter
from .infrastructure import (
    InfrastructureTestResult,
    NetworkAnalyzer,
)


class RichReporter:
    """Rich console reporter for homelab test results."""

    def __init__(self, console: Console = None):
        """Initialize rich reporter.

        Args:
            console: Rich Console instance, creates new one if None
        """
        self.console = console or Console()
        self.service_reporter = ServiceTestReporter()
        self.network_analyzer = NetworkAnalyzer()

    def show_header(self):
        """Display the main header for the test run."""
        title = Text("HOMELAB SERVICES HEALTH CHECK", style="bold blue")
        subtitle = Text(
            f"Running at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", style="dim"
        )

        header_panel = Panel(
            f"{title}\n{subtitle}",
            title="🏠 Homelab Monitor",
            border_style="blue",
            padding=(1, 2),
        )

        self.console.print(header_panel)
        self.console.print()

    def show_service_discovery(self, service_count: int):
        """Show service discovery progress.

        Args:
            service_count: Number of services discovered
        """
        self.console.print(
            f"📡 [blue]Discovered {service_count} services from Traefik configuration[/blue]"
        )
        self.console.print()

    def show_infrastructure_results(self, infra_result: InfrastructureTestResult):
        """Display infrastructure test results.

        Args:
            infra_result: Infrastructure test results
        """
        # Build all infrastructure tables
        tables = []

        # Network connectivity table
        if infra_result.ping_results:
            ping_table = Table(
                title="Network Connectivity Tests",
                show_header=True,
                header_style="bold cyan",
            )
            ping_table.add_column("Name", style="white")
            ping_table.add_column("Status")
            ping_table.add_column("Response Time")
            ping_table.add_column("Target", style="dim", no_wrap=True)

            for result in infra_result.ping_results:
                # Extract clean name (remove IP/hostname from parentheses)
                name = (
                    result.name.split(" (")[0] if " (" in result.name else result.name
                )

                if result.skipped:
                    status = (
                        f"[yellow]SKIPPED[/yellow]\n[dim]{result.skip_reason}[/dim]"
                    )
                    response_time = "-"
                elif result.success:
                    status = "[green]✅ OK[/green]"
                    response_time = (
                        f"{result.response_time:.1f}ms" if result.response_time else "-"
                    )
                else:
                    status = f"[red]❌ {result.error_message}[/red]"
                    response_time = "-"

                ping_table.add_row(name, status, response_time, result.target)

            tables.append(ping_table)

        # DNS resolution table
        if infra_result.dns_results:
            dns_table = Table(
                title="DNS Resolution Tests", show_header=True, header_style="bold cyan"
            )
            dns_table.add_column("Name", style="white")
            dns_table.add_column("Status")
            dns_table.add_column("Resolved IPs")
            dns_table.add_column("Query", style="dim", no_wrap=True)

            for result in infra_result.dns_results:
                # Extract clean name (remove query in parentheses)
                name = (
                    result.name.split(" (")[0] if " (" in result.name else result.name
                )

                if result.success:
                    status = "[green]✅ OK[/green]"
                    ips = ", ".join(result.resolved_ips) if result.resolved_ips else "-"
                else:
                    status = f"[red]❌ {result.error_message}[/red]"
                    ips = "-"

                # Show nameserver if specified
                query_display = result.query
                if result.nameserver:
                    query_display = f"{result.query} @{result.nameserver}"

                dns_table.add_row(name, status, ips, query_display)

            tables.append(dns_table)

        # Direct services table
        if infra_result.direct_service_results:
            services_table = Table(
                title="Direct Infrastructure Services",
                show_header=True,
                header_style="bold cyan",
            )
            services_table.add_column("Service", style="white")
            services_table.add_column("Status")
            services_table.add_column("Response")
            services_table.add_column("URL", style="dim", no_wrap=True)

            for result in infra_result.direct_service_results:
                if result.success:
                    status = "[green]✅ OK[/green]"
                    response = f"{result.status_code} ({result.response_time*1000:.0f}ms)"
                else:
                    status = f"[red]❌ {result.error_message}[/red]"
                    response = result.error_detail if result.error_detail else "-"

                services_table.add_row(
                    result.service_name, status, response, result.url
                )

            tables.append(services_table)

        # Combine all tables into a single infrastructure panel
        if tables:
            # Create a group of tables with spacing between them
            from rich.console import Group

            # Interleave tables with newlines, but don't add extra at the end
            grouped_items = []
            for i, table in enumerate(tables):
                grouped_items.append(table)
                if i < len(tables) - 1:  # Add newline only between tables, not after last
                    grouped_items.append("")
            
            table_group = Group(*grouped_items)

            # Determine border color based on infrastructure failures
            failed_ping = [r for r in infra_result.ping_results if not r.success and not r.skipped]
            failed_dns = [r for r in infra_result.dns_results if not r.success]
            failed_direct = [r for r in infra_result.direct_service_results if not r.success]
            has_infrastructure_failures = len(failed_ping) + len(failed_dns) + len(failed_direct) > 0
            
            infrastructure_border = "red" if has_infrastructure_failures else "green"

            infrastructure_panel = Panel(
                table_group,
                title="🔧 Infrastructure Services",
                border_style=infrastructure_border,
                padding=(1, 1),
            )

            self.console.print(infrastructure_panel)
            self.console.print()

    def show_service_results(self, results: List[ServiceTestResult]):
        """Display service test results in a rich table.

        Args:
            results: List of service test results
        """
        if not results:
            self.console.print("[yellow]No services found to test[/yellow]")
            return

        # Create services table
        services_table = Table(
            title="Traefik Services", show_header=True, header_style="bold green"
        )
        services_table.add_column("Service", style="white")
        services_table.add_column("Status")
        services_table.add_column("Response")
        services_table.add_column("Host")
        services_table.add_column("URL", style="dim", no_wrap=True)

        for result in sorted(results, key=lambda x: x.service_name):
            if result.success:
                status = "[green]✅ OK[/green]"
                response = f"{result.status_code} ({result.response_time*1000:.0f}ms)"
            else:
                status = f"[red]❌ {result.error_message}[/red]"
                response = result.error_detail if result.error_detail else "-"

            # Color code routing type by host - each host gets its own color
            routing_type = result.routing_type
            if "tower" in routing_type.lower():
                if "swag" in routing_type.lower():
                    routing_type = f"[yellow]{routing_type}[/yellow]"  # tower-swag
                else:
                    routing_type = f"[blue]{routing_type}[/blue]"      # tower
            elif "bee" in routing_type.lower():
                routing_type = f"[cyan]{routing_type}[/cyan]"         # bee
            elif "halo" in routing_type.lower():
                routing_type = f"[magenta]{routing_type}[/magenta]"   # halo  
            elif "pi" in routing_type.lower():
                routing_type = f"[green]{routing_type}[/green]"       # pi
            else:
                routing_type = f"[white]{routing_type}[/white]"       # unknown

            services_table.add_row(
                result.service_name, status, response, routing_type, result.url
            )

        # Determine border color based on service failures
        has_service_failures = any(not r.success for r in results)
        service_border = "red" if has_service_failures else "green"

        self.console.print(
            Panel(
                services_table,
                title="🌐 Service Results",
                border_style=service_border,
                padding=(0, 1),
            )
        )
        self.console.print()

    def show_analysis(
        self,
        service_results: List[ServiceTestResult],
        infra_result: InfrastructureTestResult,
    ):
        """Display comprehensive analysis and health metrics.

        Args:
            service_results: Service test results
            infra_result: Infrastructure test results
        """
        # Generate comprehensive summary including infrastructure
        service_summary = self.service_reporter.generate_summary(service_results)
        overall_summary = self._generate_overall_summary(service_results, infra_result)
        categories = service_summary["categories"]

        # Health metrics (overall including infrastructure)
        health_score = overall_summary["health_score"]
        
        # Display health status - green text only for 100% perfect
        if health_score == 100:
            health_color = "green"
            health_emoji = "🟢"
            health_status = "Perfect"
        elif health_score >= 95:
            health_color = "yellow"
            health_emoji = "🟡"
            health_status = "Excellent"
        elif health_score >= 85:
            health_color = "yellow"
            health_emoji = "🟡"
            health_status = "Good"
        elif health_score >= 70:
            health_color = "yellow"
            health_emoji = "🟠"
            health_status = "Fair"
        else:
            health_color = "red"
            health_emoji = "🔴"
            health_status = "Poor"
            
        # Always use blue border for health metrics
        health_border = "blue"

        metrics_content = f"""[bold {health_color}]{health_emoji} {health_status} Health ({health_score}%)[/bold {health_color}]

📊 [bold]Overall Statistics:[/bold]
• Working: {overall_summary["working_count"]}/{overall_summary["total_tests"]} ({overall_summary["working_count"] * 100 // overall_summary["total_tests"] if overall_summary["total_tests"] > 0 else 0}%)
• Failed: {overall_summary["failed_count"]}
• Timeouts: {service_summary["timeout_count"]}

🔀 [bold]Test Breakdown:[/bold]
• Traefik Services: {len([r for r in service_results if r.success])}/{len(service_results)} passing
• Infrastructure: {overall_summary["infrastructure_tests"] - len([r for r in infra_result.direct_service_results if not r.success])}/{overall_summary["infrastructure_tests"]} passing
• Network Connectivity: {overall_summary["ping_tests"] - len([r for r in infra_result.ping_results if not r.success and not r.skipped])}/{overall_summary["ping_tests"]} passing
• DNS Resolution: {overall_summary["dns_tests"] - len([r for r in infra_result.dns_results if not r.success])}/{overall_summary["dns_tests"]} passing"""

        metrics_panel = Panel(
            metrics_content,
            title="📈 Health Metrics",
            border_style=health_border,
            padding=(1, 2),
        )

        # Detailed analysis
        details_content = []

        # Failed services
        if categories["failed"]:
            details_content.append("[bold red]❌ Failed Services:[/bold red]")
            for result in categories["failed"][:5]:  # Show first 5
                details_content.append(
                    f"  • {result.service_name} ({result.routing_type}) - {result.error_message}"
                )
            if len(categories["failed"]) > 5:
                details_content.append(
                    f"  • ... and {len(categories['failed']) - 5} more"
                )
            details_content.append("")

        # Failed infrastructure (ping, DNS, direct services)
        failed_ping = [r for r in infra_result.ping_results if not r.success and not r.skipped]
        failed_dns = [r for r in infra_result.dns_results if not r.success]
        failed_direct = [r for r in infra_result.direct_service_results if not r.success]
        
        if failed_ping:
            details_content.append("[bold red]❌ Failed Connectivity:[/bold red]")
            for result in failed_ping[:5]:  # Show first 5
                details_content.append(
                    f"  • {result.name} - {result.error_message}"
                )
            if len(failed_ping) > 5:
                details_content.append(
                    f"  • ... and {len(failed_ping) - 5} more"
                )
            details_content.append("")
            
        if failed_dns:
            details_content.append("[bold red]❌ Failed DNS:[/bold red]")
            for result in failed_dns[:5]:  # Show first 5
                details_content.append(
                    f"  • {result.name} - {result.error_message}"
                )
            if len(failed_dns) > 5:
                details_content.append(
                    f"  • ... and {len(failed_dns) - 5} more"
                )
            details_content.append("")
            
        if failed_direct:
            details_content.append("[bold red]❌ Failed Infrastructure Services:[/bold red]")
            for result in failed_direct[:5]:  # Show first 5
                details_content.append(
                    f"  • {result.service_name} - {result.error_message}"
                )
            if len(failed_direct) > 5:
                details_content.append(
                    f"  • ... and {len(failed_direct) - 5} more"
                )
            details_content.append("")

        # Timeout services
        if categories["timeout"]:
            details_content.append("[bold yellow]⏱️  Timeout Services:[/bold yellow]")
            for result in categories["timeout"][:5]:  # Show first 5
                details_content.append(
                    f"  • {result.service_name} ({result.routing_type})"
                )
            if len(categories["timeout"]) > 5:
                details_content.append(
                    f"  • ... and {len(categories['timeout']) - 5} more"
                )
            details_content.append("")

        # Network analysis
        network_analysis = self.network_analyzer.analyze_network_layers(infra_result)
        if network_analysis["network_healthy"]:
            details_content.append(
                "[bold green]📡 Network Analysis: All layers healthy[/bold green]"
            )
        else:
            details_content.append(
                "[bold red]📡 Network Analysis: Issues detected[/bold red]"
            )
            for issue in network_analysis["issues"]:
                details_content.append(f"  • [red]{issue}[/red]")

        # Recommendations
        if (
            not network_analysis["network_healthy"]
            or categories["failed"]
            or categories["timeout"]
        ):
            details_content.append("")
            details_content.append("[bold]🔧 Recommendations:[/bold]")

            # Add network recommendations
            for rec in network_analysis["recommendations"]:
                details_content.append(f"  • {rec}")

            # Add service-specific recommendations
            if len(categories["failed"]) > 5:
                details_content.append(
                    "  • High failure rate - check network connectivity"
                )
                details_content.append(
                    "  • Verify Tailscale connection and DNS resolution"
                )
            elif categories["failed"]:
                details_content.append("  • Investigate specific service failures")
                details_content.append(
                    "  • Check service containers are running on Tower"
                )

            if categories["timeout"]:
                details_content.append(
                    "  • Timeout services may indicate network issues"
                )
                details_content.append(
                    "  • Consider increasing timeout values for slow services"
                )

        details_panel = Panel(
            (
                "\n".join(details_content)
                if details_content
                else "[green]🎉 All systems operational![/green]"
            ),
            title="🔍 Detailed Analysis",
            border_style="blue",
            padding=(1, 2),
        )

        # Display panels side by side without forcing height
        from rich.columns import Columns

        self.console.print(
            Columns([metrics_panel, details_panel], equal=False, expand=True)
        )
        self.console.print()

    def show_completion(self, success: bool):
        """Show test completion status.

        Args:
            success: Whether all tests passed
        """
        if success:
            completion_panel = Panel(
                "[bold green]🎉 Health check completed successfully![/bold green]\n[green]All critical services are operational[/green]",
                title="✅ Test Complete",
                border_style="green",
                padding=(1, 2),
            )
        else:
            completion_panel = Panel(
                "[bold red]❌ Health check completed with failures[/bold red]\n[red]Some services need attention[/red]",
                title="⚠️  Test Complete",
                border_style="red",
                padding=(1, 2),
            )

        self.console.print(completion_panel)

    def create_progress_context(self, total_services: int):
        """Create a progress context for tracking test execution.

        Args:
            total_services: Total number of services to test

        Returns:
            Progress context manager
        """
        return Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TimeElapsedColumn(),
            console=self.console,
        )

    def export_json_report(
        self,
        service_results: List[ServiceTestResult],
        infra_result: InfrastructureTestResult,
        output_file: str,
    ):
        """Export test results to JSON file.

        Args:
            service_results: Service test results
            infra_result: Infrastructure test results
            output_file: Output file path
        """
        import json
        from datetime import datetime

        # Convert results to JSON-serializable format
        report = {
            "timestamp": datetime.now().isoformat(),
            "summary": self.service_reporter.generate_summary(service_results),
            "service_results": [
                {
                    "name": r.service_name,
                    "url": r.url,
                    "routing_type": r.routing_type,
                    "status_code": r.status_code,
                    "response_size": r.response_size,
                    "response_time": r.response_time,
                    "redirect_count": r.redirect_count,
                    "success": r.success,
                    "error_message": r.error_message,
                    "error_detail": r.error_detail,
                }
                for r in service_results
            ],
            "infrastructure": {
                "ping_results": [
                    {
                        "name": r.name,
                        "target": r.target,
                        "success": r.success,
                        "response_time": r.response_time,
                        "error_message": r.error_message,
                        "skipped": r.skipped,
                        "skip_reason": r.skip_reason,
                    }
                    for r in infra_result.ping_results
                ],
                "dns_results": [
                    {
                        "name": r.name,
                        "query": r.query,
                        "nameserver": r.nameserver,
                        "success": r.success,
                        "resolved_ips": r.resolved_ips,
                        "error_message": r.error_message,
                    }
                    for r in infra_result.dns_results
                ],
            },
            "network_analysis": self.network_analyzer.analyze_network_layers(
                infra_result
            ),
        }

        with open(output_file, "w") as f:
            json.dump(report, f, indent=2)

        self.console.print(f"[green]📄 JSON report exported to: {output_file}[/green]")

    def _generate_overall_summary(
        self,
        service_results: List,
        infra_result: InfrastructureTestResult,
    ) -> Dict[str, any]:
        """Generate comprehensive summary including all test types.

        Args:
            service_results: Service test results
            infra_result: Infrastructure test results

        Returns:
            Overall summary including all tests
        """
        # Count infrastructure tests (excluding skipped ping tests)
        ping_tests = [r for r in infra_result.ping_results if not r.skipped]
        dns_tests = infra_result.dns_results
        direct_tests = infra_result.direct_service_results
        
        # Count successes
        working_services = sum(1 for r in service_results if r.success)
        working_ping = sum(1 for r in ping_tests if r.success)
        working_dns = sum(1 for r in dns_tests if r.success)
        working_direct = sum(1 for r in direct_tests if r.success)
        
        # Count failures
        failed_services = sum(1 for r in service_results if not r.success)
        failed_ping = sum(1 for r in ping_tests if not r.success)
        failed_dns = sum(1 for r in dns_tests if not r.success)
        failed_direct = sum(1 for r in direct_tests if not r.success)
        
        # Totals
        total_working = working_services + working_ping + working_dns + working_direct
        total_failed = failed_services + failed_ping + failed_dns + failed_direct
        total_tests = total_working + total_failed
        
        # Calculate overall health score
        health_score = int((total_working * 100) / total_tests) if total_tests > 0 else 0
        
        return {
            "total_tests": total_tests,
            "working_count": total_working,
            "failed_count": total_failed,
            "health_score": health_score,
            "ping_tests": len(ping_tests),
            "dns_tests": len(dns_tests),
            "infrastructure_tests": len(direct_tests),
            "service_tests": len(service_results),
        }
