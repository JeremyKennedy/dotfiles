"""Command-line interface for homelab testing framework."""

import argparse
import asyncio
import json
import sys

from rich.console import Console

from .config import get_config, ConfigError
from .traefik import TraefikClient
from .services import ServiceTester
from .infrastructure import InfrastructureTester
from .reporting import RichReporter
from .system_info import run_system_info


async def run_full_test(output_format: str = "rich", verbose: bool = False) -> int:
    """Run complete homelab health check.

    Args:
        output_format: Output format (rich, json, plain)
        verbose: Enable verbose output

    Returns:
        Exit code (0 for success, 1 for failures)
    """
    console = Console()

    try:
        # Load configuration
        config = get_config()

        # Create reporter
        reporter = RichReporter(console if output_format == "rich" else None)

        if output_format == "rich":
            reporter.show_header()

        # Initialize clients
        traefik_client = TraefikClient(api_url=config.traefik.api_url)
        service_tester = ServiceTester(
            timeout=config.timeouts.http, follow_redirects=config.follow_redirects
        )
        infrastructure_tester = InfrastructureTester(
            timeout=config.timeouts.infrastructure
        )

        # Test infrastructure first
        if output_format == "rich":
            console.print("[blue]🔧 Testing infrastructure...[/blue]")

        infra_result = await infrastructure_tester.test_all_infrastructure(config)

        if output_format == "rich":
            reporter.show_infrastructure_results(infra_result)

        # Discover and test Traefik services
        if output_format == "rich":
            console.print("[blue]📡 Discovering Traefik services...[/blue]")

        try:
            traefik_services = await traefik_client.get_services(config.traefik_paths)

            if output_format == "rich":
                reporter.show_service_discovery(len(traefik_services))
                console.print("[blue]🌐 Testing services...[/blue]")
                console.print()

            # Test services with progress tracking
            if output_format == "rich" and len(traefik_services) > 0:
                with reporter.create_progress_context(
                    len(traefik_services)
                ) as progress:
                    task = progress.add_task(
                        "Testing services...", total=len(traefik_services)
                    )

                    service_results = []
                    if config.parallel_execution:
                        # Test all services concurrently
                        service_results = await service_tester.test_services(
                            traefik_services
                        )
                        progress.update(task, completed=len(traefik_services))
                    else:
                        # Test services sequentially with progress updates
                        for i, service in enumerate(traefik_services):
                            result = await service_tester.test_service(service)
                            service_results.append(result)
                            progress.update(task, completed=i + 1)
            else:
                # Non-rich output or no services
                if config.parallel_execution:
                    service_results = await service_tester.test_services(
                        traefik_services
                    )
                else:
                    service_results = []
                    for service in traefik_services:
                        result = await service_tester.test_service(service)
                        service_results.append(result)

        except Exception as e:
            console.print(
                f"[red]❌ Failed to discover or test Traefik services: {e}[/red]"
            )
            service_results = []
            traefik_services = []

        # Display results
        if output_format == "rich":
            reporter.show_service_results(service_results)
            reporter.show_analysis(service_results, infra_result)
        elif output_format == "json":
            # JSON output
            from .services import ServiceTestReporter

            service_reporter = ServiceTestReporter()
            summary = service_reporter.generate_summary(service_results)

            json_output = {
                "summary": summary,
                "service_results": [
                    {
                        "name": r.service_name,
                        "url": r.url,
                        "routing_type": r.routing_type,
                        "status_code": r.status_code,
                        "success": r.success,
                        "error_message": r.error_message,
                    }
                    for r in service_results
                ],
                "infrastructure": {
                    "ping_results": [
                        {
                            "name": r.name,
                            "target": r.target,
                            "success": r.success,
                            "error_message": r.error_message,
                        }
                        for r in infra_result.ping_results
                    ],
                    "dns_results": [
                        {
                            "name": r.name,
                            "query": r.query,
                            "success": r.success,
                            "resolved_ips": r.resolved_ips,
                        }
                        for r in infra_result.dns_results
                    ],
                },
            }

            print(json.dumps(json_output, indent=2))
        else:
            # Plain text output
            from .services import ServiceTestReporter

            service_reporter = ServiceTestReporter()
            summary = service_reporter.generate_summary(service_results)

            print(f"Health Score: {summary['health_score']}%")
            print(f"Working: {summary['working_count']}/{summary['total_tests']}")
            print(f"Failed: {summary['failed_count']}")
            print(f"Timeouts: {summary['timeout_count']}")


        # Determine success/failure (include all failures including ping)
        failed_services = [r for r in service_results if not r.success]
        failed_ping = [r for r in infra_result.ping_results if not r.success and not r.skipped]
        failed_infrastructure = [
            r for r in infra_result.dns_results if not r.success
        ] + [r for r in infra_result.direct_service_results if not r.success]

        total_failures = len(failed_services) + len(failed_ping) + len(failed_infrastructure)

        if output_format == "rich":
            reporter.show_completion(total_failures == 0)

        return 0 if total_failures == 0 else 1

    except ConfigError as e:
        console.print(f"[red]❌ Configuration error: {e}[/red]")
        return 1
    except KeyboardInterrupt:
        console.print("\n[yellow]⚠️  Test interrupted by user[/yellow]")
        return 1
    except Exception as e:
        console.print(f"[red]❌ Unexpected error: {e}[/red]")
        if verbose:
            import traceback

            console.print(traceback.format_exc())
        return 1


async def run_core_only(output_format: str = "rich", verbose: bool = False) -> int:
    """Run only core infrastructure tests.

    Args:
        output_format: Output format (rich, json, plain)
        verbose: Enable verbose output

    Returns:
        Exit code
    """
    console = Console()

    try:
        config = get_config()
        infrastructure_tester = InfrastructureTester(
            timeout=config.timeouts.infrastructure
        )
        reporter = RichReporter(console if output_format == "rich" else None)

        if output_format == "rich":
            reporter.show_header()
            console.print("[blue]🔧 Testing core infrastructure only...[/blue]")

        infra_result = await infrastructure_tester.test_all_infrastructure(config)
        
        if output_format == "rich":
            reporter.show_infrastructure_results(infra_result)
        elif output_format == "json":
            import json
            json_output = {
                "infrastructure": {
                    "ping_results": [
                        {
                            "name": r.name,
                            "target": r.target,
                            "success": r.success,
                            "error_message": r.error_message,
                        }
                        for r in infra_result.ping_results
                    ],
                    "dns_results": [
                        {
                            "name": r.name,
                            "query": r.query,
                            "success": r.success,
                            "resolved_ips": r.resolved_ips,
                        }
                        for r in infra_result.dns_results
                    ],
                }
            }
            print(json.dumps(json_output, indent=2))

        # Check for critical failures (include all failures including ping)
        failed_ping = [r for r in infra_result.ping_results if not r.success and not r.skipped]
        failed_infrastructure = [
            r for r in infra_result.dns_results if not r.success
        ] + [r for r in infra_result.direct_service_results if not r.success]

        total_core_failures = len(failed_ping) + len(failed_infrastructure)

        if output_format == "rich":
            reporter.show_completion(total_core_failures == 0)

        return 0 if total_core_failures == 0 else 1

    except Exception as e:
        if output_format == "rich":
            console.print(f"[red]❌ Core infrastructure test failed: {e}[/red]")
        else:
            print(f"Error: {e}")
        if verbose:
            import traceback
            if output_format == "rich":
                console.print(traceback.format_exc())
            else:
                traceback.print_exc()
        return 1


def main() -> int:
    """Main entry point for CLI."""
    parser = argparse.ArgumentParser(
        description="Homelab services health check framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Full health check
  %(prog)s --core                   # Core infrastructure only
  %(prog)s --output json            # JSON output
  %(prog)s info                     # System information
  %(prog)s info --full              # Detailed system information
        """,
    )

    parser.add_argument("--output", "-o", choices=["rich", "json", "plain"], default="rich", help="Output format")
    parser.add_argument("--core", action="store_true", help="Test core infrastructure only")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    # Add subcommands
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Info subcommand
    info_parser = subparsers.add_parser("info", help="Show system information")
    info_parser.add_argument("--full", action="store_true", help="Show detailed information")
    info_parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    # Run appropriate test mode
    try:
        if args.command == "info":
            # Run system info command
            return asyncio.run(run_system_info(args.full, args.json))
        elif args.core:
            return asyncio.run(run_core_only(args.output, args.verbose))
        else:
            return asyncio.run(run_full_test(args.output, args.verbose))
    except KeyboardInterrupt:
        print("\n⚠️  Interrupted by user")
        return 1


if __name__ == "__main__":
    sys.exit(main())
