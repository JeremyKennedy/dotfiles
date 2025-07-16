"""System information gathering and reporting for homelab hosts."""

import asyncio
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import subprocess

from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.columns import Columns
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich import box


@dataclass
class HostInfo:
    """Information about a single host."""
    name: str
    ip: str
    state_version: str
    architecture: str
    online: bool = False
    ping_ms: Optional[float] = None
    last_deploy: Optional[datetime] = None
    system_generation_time: Optional[datetime] = None
    uptime: Optional[str] = None
    load_average: Optional[Tuple[float, float, float]] = None
    memory_used_percent: Optional[float] = None
    disk_used_percent: Optional[float] = None
    package_count: Optional[int] = None
    system_size_mb: Optional[float] = None
    dns_working: Optional[bool] = None
    internet_working: Optional[bool] = None
    kernel_version: Optional[str] = None
    nixos_version: Optional[str] = None
    tailscale_status: Optional[str] = None
    tailscale_ip: Optional[str] = None
    tailscale_auth_needed: bool = False
    tailscale_auth_url: Optional[str] = None


class SystemInfoGatherer:
    """Gathers system information from NixOS hosts."""
    
    def __init__(self, timeout: float = 10.0, console: Optional[Console] = None):
        self.timeout = timeout
        self.deploy_log_path = Path.home() / ".deploy-times.json"
        self.console = console
        self._hosts_needing_auth = {}
        self._hosts_auth_failed = set()  # Only hosts where auth was skipped/failed
        self._hosts_auth_prompted = set()
        
    async def gather_all_info(self, hosts: List[str], full_mode: bool = False) -> Dict[str, HostInfo]:
        """Gather information for all hosts in parallel."""
        if self.console:
            self.console.print("[blue]🔍 Discovering hosts...[/blue]")
        
        # First gather basic info for all hosts
        basic_tasks = []
        for host in hosts:
            task = asyncio.create_task(self._get_nix_info(host))
            basic_tasks.append((host, task))
        
        results = {}
        for host, task in basic_tasks:
            try:
                results[host] = await task
                if self.console:
                    self.console.print(f"  [green]✓[/green] Found {host}: {results[host].ip}")
            except Exception:
                results[host] = HostInfo(
                    name=host,
                    ip="unknown",
                    state_version="unknown",
                    architecture="unknown",
                    online=False
                )
                if self.console:
                    self.console.print(f"  [red]✗[/red] Failed to find {host}")
        
        if self.console:
            self.console.print("\n[blue]🏓 Checking connectivity...[/blue]")
        
        # Check connectivity for all hosts
        ping_tasks = []
        for host, info in results.items():
            task = asyncio.create_task(self._check_host_online(info.ip))
            ping_tasks.append((host, info, task))
        
        online_hosts = []
        for host, info, task in ping_tasks:
            try:
                info.online, info.ping_ms = await task
                if info.online:
                    online_hosts.append((host, info))
                    if self.console:
                        self.console.print(f"  [green]✓[/green] {host} is online ({info.ping_ms:.0f}ms)")
                else:
                    if self.console:
                        self.console.print(f"  [red]✗[/red] {host} is offline")
            except Exception:
                if self.console:
                    self.console.print(f"  [red]✗[/red] {host} ping failed")
        
        if online_hosts and self.console:
            self.console.print("\n[blue]📊 Gathering system stats...[/blue]")
            self.console.print(f"  [dim]Checking SSH access to {len(online_hosts)} hosts...[/dim]")
        
        # Gather detailed info for online hosts
        for host, info in online_hosts:
            if self.console:
                self.console.print(f"  [dim]→ Connecting to {host}...[/dim]")
            
            try:
                await self._gather_online_host_info(info, full_mode)
                if self.console and info.ip not in self._hosts_auth_failed:
                    self.console.print(f"  [green]✓[/green] {host} stats collected")
            except Exception:
                if self.console:
                    self.console.print(f"  [yellow]⚠[/yellow] {host} partial stats")
        
        return results
    
    async def _gather_online_host_info(self, info: HostInfo, full_mode: bool) -> None:
        """Gather detailed information for an online host."""
        # First check if we can SSH to the host (Tailscale auth check)
        if not await self._check_ssh_access(info):
            if self.console and info.ip not in self._hosts_auth_failed:
                self.console.print(f"  [yellow]⚠ Skipping {info.name} (SSH access check failed)[/yellow]")
            return
            
        # Gather system info via SSH
        await asyncio.gather(
            self._get_system_stats(info),
            self._get_network_status(info),
            self._get_deploy_time(info),
            self._get_nixos_version(info),
            self._get_tailscale_status(info)
        )
        
        if full_mode:
            # Additional expensive operations for full mode
            if self.console:
                self.console.print(f"  [dim]  → Counting packages on {info.name}...[/dim]")
            await self._get_package_count(info)
            
            if self.console:
                self.console.print(f"  [dim]  → Measuring system size on {info.name}...[/dim]")
            await self._get_system_size(info)
    
    async def _get_nix_info(self, host: str) -> HostInfo:
        """Get basic host information from nix configuration."""
        try:
            # Get state version
            state_version = await self._run_local_command(
                f"nix eval --raw .#nixosConfigurations.{host}.config.system.stateVersion"
            )
            
            # Get IP address
            ip = await self._run_local_command(
                f"nix eval --raw --impure --expr '(import ./modules/core/hosts.nix).hosts.{host}.ip'"
            )
            
            # Also get Tailscale domain for SSH
            ts_domain = await self._run_local_command(
                f"nix eval --raw --impure --expr '(import ./modules/core/hosts.nix).hosts.{host}.tailscaleDomain' 2>/dev/null"
            )
            
            # Get architecture
            arch = await self._run_local_command(
                f"nix eval --raw .#nixosConfigurations.{host}.config.nixpkgs.hostPlatform.system"
            )
            
            return HostInfo(
                name=host,
                ip=ip or "unknown",
                state_version=state_version or "unknown",
                architecture=arch or "unknown"
            )
        except Exception:
            return HostInfo(
                name=host,
                ip="unknown",
                state_version="unknown",
                architecture="unknown"
            )
    
    async def _check_ssh_access(self, info: HostInfo) -> bool:
        """Check if we can SSH to the host, handling Tailscale auth if needed."""
        # Skip if auth was already failed/skipped
        if info.ip in self._hosts_auth_failed:
            return False
            
        # Try a simple SSH command with special handling for Tailscale
        try:
            # Use a shorter timeout for the auth check
            ssh_cmd = f"ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@{info.ip} 'echo ok' 2>&1"
            
            proc = await asyncio.create_subprocess_shell(
                ssh_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            
            try:
                # Wait just 2 seconds - if Tailscale needs auth, it will hang
                output, _ = await asyncio.wait_for(proc.communicate(), timeout=2.0)
                output_text = output.decode() if output else ""
                
                # Check if it succeeded
                if proc.returncode == 0 and "ok" in output_text:
                    return True
                    
                # Check for Tailscale auth message
                if "Tailscale SSH" in output_text and "login.tailscale.com" in output_text:
                    # Extract auth URL
                    for line in output_text.split('\n'):
                        if "https://login.tailscale.com" in line:
                            auth_url = line.strip()
                            for prefix in ["# To authenticate, visit: ", "To authenticate, visit: "]:
                                auth_url = auth_url.replace(prefix, "")
                            
                            if await self._handle_tailscale_auth(info.ip, auth_url.strip()):
                                # Retry after auth
                                return await self._check_ssh_access_simple(info)
                            else:
                                self._hosts_auth_failed.add(info.ip)
                                return False
                
                return False
                
            except asyncio.TimeoutError:
                # Timeout might mean Tailscale auth is needed
                # Try to get the auth URL with a different approach
                proc.terminate()
                
                # Run a command that will definitely trigger the auth message
                auth_proc = await asyncio.create_subprocess_shell(
                    f"timeout 1 ssh -o StrictHostKeyChecking=no root@{info.ip} 'echo test' 2>&1 || true",
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT
                )
                
                auth_output, _ = await auth_proc.communicate()
                auth_text = auth_output.decode() if auth_output else ""
                
                if "login.tailscale.com" in auth_text:
                    for line in auth_text.split('\n'):
                        if "https://login.tailscale.com" in line:
                            auth_url = line.strip()
                            for prefix in ["# To authenticate, visit: ", "To authenticate, visit: "]:
                                auth_url = auth_url.replace(prefix, "")
                            
                            if await self._handle_tailscale_auth(info.ip, auth_url.strip()):
                                return await self._check_ssh_access_simple(info)
                            else:
                                self._hosts_auth_failed.add(info.ip)
                                return False
                
                # Just a regular timeout
                self._hosts_auth_failed.add(info.ip)
                return False
                
        except Exception:
            self._hosts_auth_failed.add(info.ip)
            return False
    
    async def _check_ssh_access_simple(self, info: HostInfo) -> bool:
        """Simple SSH access check after auth."""
        if self.console:
            self.console.print("  [dim]Testing connection...[/dim]")
            
        try:
            # Use direct SSH without the _run_ssh_command wrapper to avoid recursion
            ssh_cmd = f"ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@{info.ip} 'echo ok'"
            proc = await asyncio.create_subprocess_shell(
                ssh_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL
            )
            
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=10.0)
            result = stdout.decode().strip() if stdout else ""
            success = proc.returncode == 0 and result == "ok"
            
            if self.console:
                if success:
                    self.console.print(f"  [green]✓ Successfully connected to {info.name}[/green]")
                else:
                    self.console.print(f"  [red]✗ Failed to connect to {info.name} after authentication[/red]")
                    self._hosts_auth_failed.add(info.ip)
            
            return success
        except Exception as e:
            if self.console:
                self.console.print(f"  [red]✗ Connection test failed: {str(e)}[/red]")
            self._hosts_auth_failed.add(info.ip)
            return False
    
    async def _check_host_online(self, ip: str) -> Tuple[bool, Optional[float]]:
        """Check if host is online and measure ping time."""
        if ip == "unknown":
            return False, None
            
        try:
            result = await self._run_local_command(
                f"ping -c 1 -W 2 {ip} | grep 'time=' | sed 's/.*time=//; s/ ms.*//'"
            )
            if result:
                return True, float(result)
            return False, None
        except Exception:
            return False, None
    
    async def _get_system_stats(self, info: HostInfo) -> None:
        """Get system statistics via SSH."""
        try:
            # For local host, run commands directly
            if info.name == "navi" and info.ip == "192.168.1.250":
                # Local commands
                uptime_output = await self._run_local_command("uptime")
                if uptime_output:
                    parts = uptime_output.strip().split("up")
                    if len(parts) > 1:
                        uptime_part = parts[1].split(",")[0].strip()
                        info.uptime = uptime_part
                    
                    if "load average:" in uptime_output:
                        load_part = uptime_output.split("load average:")[-1].strip()
                        loads = [l.strip() for l in load_part.split(",")]
                        if len(loads) >= 3:
                            try:
                                info.load_average = (float(loads[0]), float(loads[1]), float(loads[2]))
                            except ValueError:
                                pass
                
                mem_output = await self._run_local_command("free | grep Mem | awk '{print int(($2-$7)/$2 * 100)}'")
                if mem_output:
                    try:
                        info.memory_used_percent = float(mem_output.strip())
                    except ValueError:
                        pass
                
                disk_output = await self._run_local_command("df / | tail -1 | awk '{print $5}' | sed 's/%//'")
                if disk_output:
                    try:
                        info.disk_used_percent = float(disk_output.strip())
                    except ValueError:
                        pass
                        
                return
            # Get uptime and load
            uptime_output = await self._run_ssh_command(
                info.ip,
                "uptime"
            )
            if uptime_output:
                # Parse uptime output
                # Example: " 01:17:02  up  22:55,  0 users,  load average: 0.19, 0.25, 0.23"
                parts = uptime_output.strip().split("up")
                if len(parts) > 1:
                    uptime_part = parts[1].split(",")[0].strip()
                    info.uptime = uptime_part
            
            # Get load average from uptime output
            if uptime_output and "load average:" in uptime_output:
                load_part = uptime_output.split("load average:")[-1].strip()
                loads = [l.strip() for l in load_part.split(",")]
                if len(loads) >= 3:
                    try:
                        info.load_average = (float(loads[0]), float(loads[1]), float(loads[2]))
                    except ValueError:
                        pass
            
            # Get memory usage
            mem_output = await self._run_ssh_command(
                info.ip,
                "free | grep Mem | awk '{print int(($2-$7)/$2 * 100)}'"
            )
            if mem_output:
                try:
                    info.memory_used_percent = float(mem_output.strip())
                except ValueError:
                    pass
            
            # Get disk usage
            disk_output = await self._run_ssh_command(
                info.ip,
                "df / | tail -1 | awk '{print $5}' | sed 's/%//'"
            )
            if disk_output:
                try:
                    info.disk_used_percent = float(disk_output.strip())
                except ValueError:
                    pass
            
            # Get kernel version
            kernel_output = await self._run_ssh_command(
                info.ip,
                "uname -r"
            )
            if kernel_output:
                info.kernel_version = kernel_output.strip()
                
        except Exception:
            pass
    
    async def _get_network_status(self, info: HostInfo) -> None:
        """Check DNS and internet connectivity."""
        try:
            # Check DNS
            dns_output = await self._run_ssh_command(
                info.ip,
                "nslookup google.com 2>&1 | grep -q 'Address:' && echo 'ok' || echo 'fail'"
            )
            info.dns_working = dns_output and dns_output.strip() == "ok"
            
            # Check internet
            internet_output = await self._run_ssh_command(
                info.ip,
                "ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && echo 'ok' || echo 'fail'"
            )
            info.internet_working = internet_output and internet_output.strip() == "ok"
        except Exception:
            pass
    
    async def _get_nixos_version(self, info: HostInfo) -> None:
        """Get NixOS version information."""
        try:
            version_output = await self._run_ssh_command(
                info.ip,
                "nixos-version"
            )
            if version_output:
                info.nixos_version = version_output.strip()
        except Exception:
            pass
    
    async def _get_tailscale_status(self, info: HostInfo) -> None:
        """Get Tailscale status and IP."""
        try:
            # Get Tailscale status
            status_output = await self._run_ssh_command(
                info.ip,
                "tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo 'not installed'"
            )
            if status_output:
                info.tailscale_status = status_output.strip()
            
            # Get Tailscale IP if running
            if info.tailscale_status == "Running":
                ip_output = await self._run_ssh_command(
                    info.ip,
                    "tailscale ip -4 2>/dev/null | head -1"
                )
                if ip_output:
                    info.tailscale_ip = ip_output.strip()
        except Exception:
            pass
    
    async def _get_package_count(self, info: HostInfo) -> None:
        """Get number of installed packages (full mode only)."""
        try:
            count_output = await self._run_ssh_command(
                info.ip,
                "nix-store -q --requisites /run/current-system | wc -l"
            )
            if count_output:
                info.package_count = int(count_output.strip())
        except Exception:
            pass
    
    async def _get_system_size(self, info: HostInfo) -> None:
        """Get system closure size (full mode only)."""
        try:
            # For local host, run directly
            if info.name == "navi" and info.ip == "192.168.1.250":
                size_output = await self._run_local_command(
                    "du -sh /run/current-system 2>/dev/null | awk '{print $1}'"
                )
            else:
                size_output = await self._run_ssh_command(
                    info.ip,
                    "du -sh /run/current-system 2>/dev/null | awk '{print $1}'"
                )
            
            if size_output:
                size_str = size_output.strip()
                # Convert to MB
                if size_str.endswith('G'):
                    info.system_size_mb = float(size_str[:-1]) * 1024
                elif size_str.endswith('M'):
                    info.system_size_mb = float(size_str[:-1])
                elif size_str.endswith('K'):
                    info.system_size_mb = float(size_str[:-1]) / 1024
        except Exception:
            pass
    
    async def _get_deploy_time(self, info: HostInfo) -> None:
        """Get last deployment time from log and system generation time."""
        try:
            # Get from our deployment log
            if self.deploy_log_path.exists():
                with open(self.deploy_log_path) as f:
                    deploy_times = json.load(f)
                    if info.name in deploy_times:
                        info.last_deploy = datetime.fromisoformat(deploy_times[info.name])
            
            # Also get system generation time
            gen_time_output = await self._run_ssh_command(
                info.ip,
                "stat -c %Y /run/current-system 2>/dev/null"
            )
            if gen_time_output:
                timestamp = int(gen_time_output.strip())
                info.system_generation_time = datetime.fromtimestamp(timestamp, tz=timezone.utc)
        except Exception:
            pass
    
    async def _run_local_command(self, cmd: str) -> Optional[str]:
        """Run a command locally."""
        try:
            # Change to repository root for nix commands
            if cmd.startswith("nix "):
                cmd = f"cd ../.. && {cmd}"
            
            proc = await asyncio.create_subprocess_shell(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL
            )
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=self.timeout)
            if proc.returncode == 0:
                return stdout.decode().strip()
            return None
        except Exception:
            return None
    
    async def _run_ssh_command(self, host: str, cmd: str) -> Optional[str]:
        """Run a command on a remote host via SSH."""
        # Only skip if auth explicitly failed
        if host in self._hosts_auth_failed:
            return None
            
        # Use double quotes and escape properly
        escaped_cmd = cmd.replace("'", "'\"'\"'")
        ssh_cmd = f"ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@{host} '{escaped_cmd}'"
        
        try:
            proc = await asyncio.create_subprocess_shell(
                ssh_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=5.0)
                
                # Check for Tailscale authentication message
                stderr_text = stderr.decode() if stderr else ""
                stdout_text = stdout.decode() if stdout else ""
                combined_text = stderr_text + stdout_text
                
                if "Tailscale SSH requires" in combined_text and "login.tailscale.com" in combined_text:
                    # Extract the auth URL
                    lines = combined_text.split('\n')
                    for line in lines:
                        if "https://login.tailscale.com" in line:
                            # Clean up the URL
                            auth_url = line.strip()
                            auth_url = auth_url.replace("# To authenticate, visit: ", "")
                            auth_url = auth_url.replace("To authenticate, visit: ", "")
                            auth_url = auth_url.strip()
                            
                            # Handle auth interactively
                            if await self._handle_tailscale_auth(host, auth_url):
                                # Try the command again
                                return await self._run_ssh_command_direct(host, cmd)
                            else:
                                self._hosts_auth_failed.add(host)
                                return None
                
                if proc.returncode == 0:
                    return stdout.decode().strip()
                return None
            except asyncio.TimeoutError:
                proc.terminate()
                # Don't add to failed set for timeouts - might just be slow
                return None
        except Exception:
            return None
    
    async def _run_ssh_command_direct(self, host: str, cmd: str) -> Optional[str]:
        """Run SSH command without auth handling."""
        escaped_cmd = cmd.replace("'", "'\"'\"'")
        ssh_cmd = f"ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@{host} '{escaped_cmd}'"
        
        try:
            proc = await asyncio.create_subprocess_shell(
                ssh_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL
            )
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=10.0)
            if proc.returncode == 0:
                return stdout.decode().strip()
        except Exception:
            pass
        return None
    
    async def _handle_tailscale_auth(self, host: str, auth_url: str) -> bool:
        """Handle Tailscale authentication interactively."""
        if not self.console:
            return False
        
        # Only prompt once per host
        if host in self._hosts_auth_prompted:
            return False
        self._hosts_auth_prompted.add(host)
            
        self.console.print(f"\n[bold yellow]🔐 Tailscale SSH Authentication Required[/bold yellow]")
        self.console.print(f"Host: [cyan]{host}[/cyan]")
        self.console.print(f"Auth URL: [cyan underline]{auth_url}[/cyan underline]")
        self.console.print("\n[dim]Open the URL in your browser and authenticate.[/dim]")
        self.console.print("Press [bold]Enter[/bold] when done, or [bold]'s'[/bold] to skip: ", end="")
        
        # Wait for user input
        loop = asyncio.get_event_loop()
        try:
            response = await loop.run_in_executor(None, input)
            if response.lower() == 's':
                self.console.print(f"\n[dim]Skipping {host} (Tailscale auth required)[/dim]")
                return False
            else:
                self.console.print("\n[green]✓ Authentication confirmed, retrying connection...[/green]")
                # Give Tailscale a moment to update
                await asyncio.sleep(2)
                return True
        except Exception:
            return False
    
    def save_deploy_time(self, host: str) -> None:
        """Save deployment time for a host."""
        deploy_times = {}
        if self.deploy_log_path.exists():
            try:
                with open(self.deploy_log_path) as f:
                    deploy_times = json.load(f)
            except Exception:
                pass
        
        deploy_times[host] = datetime.now(tz=timezone.utc).isoformat()
        
        with open(self.deploy_log_path, 'w') as f:
            json.dump(deploy_times, f, indent=2)


class SystemInfoReporter:
    """Reports system information in rich format."""
    
    def __init__(self, console: Console):
        self.console = console
    
    def format_relative_time(self, dt: datetime) -> str:
        """Format datetime as relative time."""
        if not dt:
            return "unknown"
        
        now = datetime.now(tz=timezone.utc)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        
        delta = now - dt
        seconds = delta.total_seconds()
        
        if seconds < 60:
            return f"{int(seconds)}s ago"
        elif seconds < 3600:
            return f"{int(seconds / 60)}m ago"
        elif seconds < 86400:
            return f"{int(seconds / 3600)}h ago"
        elif seconds < 604800:
            return f"{int(seconds / 86400)}d ago"
        else:
            return f"{int(seconds / 604800)}w ago"
    
    def show_summary(self, hosts: Dict[str, HostInfo], full_mode: bool = False) -> None:
        """Show system information summary."""
        # Header
        self.console.print()
        self.console.print(Panel.fit(
            "[bold cyan]Homelab System Information[/bold cyan]",
            border_style="cyan"
        ))
        
        # Create main table
        table = Table(
            title="Host Status",
            box=box.ROUNDED,
            show_header=True,
            header_style="bold cyan"
        )
        
        # Define columns
        table.add_column("Host", style="bold")
        table.add_column("Status", justify="center")
        table.add_column("NixOS", justify="center")
        table.add_column("Arch", justify="center")
        table.add_column("Last Deploy", justify="right")
        table.add_column("Uptime", justify="right")
        table.add_column("Load", justify="center")
        table.add_column("Mem %", justify="center")
        table.add_column("Disk %", justify="center")
        
        if full_mode:
            table.add_column("Packages", justify="right")
            table.add_column("Size", justify="right")
        
        # Add rows
        for name in ["navi", "bee", "halo", "pi"]:  # Fixed order
            if name not in hosts:
                continue
            
            info = hosts[name]
            
            # Status indicator
            if info.online:
                status = f"[green]● {info.ping_ms:.0f}ms[/green]" if info.ping_ms else "[green]●[/green]"
            else:
                status = "[red]●[/red]"
            
            # NixOS version - show actual running version
            nixos_ver = info.state_version
            if info.nixos_version:
                # Extract version from full string like "25.11.20250708.9807714 (Vicuña)"
                parts = info.nixos_version.split()
                if len(parts) > 0:
                    version_parts = parts[0].split('.')
                    if len(version_parts) >= 2:
                        nixos_ver = f"{version_parts[0]}.{version_parts[1]}"
                        # Add indicator if it's a pre-release
                        if "pre" in parts[0]:
                            nixos_ver += "pre"
            
            # Format values - use system generation time as it's more accurate
            deploy_time = info.system_generation_time or info.last_deploy
            last_deploy = self.format_relative_time(deploy_time) if deploy_time else "unknown"
            uptime = info.uptime or "-"
            
            # Load with color coding
            if info.load_average:
                load = f"{info.load_average[0]:.1f}"
                if info.load_average[0] > 2.0:
                    load = f"[red]{load}[/red]"
                elif info.load_average[0] > 1.0:
                    load = f"[yellow]{load}[/yellow]"
            else:
                load = "-"
            
            # Memory with color coding
            if info.memory_used_percent is not None:
                mem = f"{info.memory_used_percent:.0f}%"
                if info.memory_used_percent > 90:
                    mem = f"[red]{mem}[/red]"
                elif info.memory_used_percent > 80:
                    mem = f"[yellow]{mem}[/yellow]"
            else:
                mem = "-"
            
            # Disk with color coding
            if info.disk_used_percent is not None:
                disk = f"{info.disk_used_percent:.0f}%"
                if info.disk_used_percent > 90:
                    disk = f"[red]{disk}[/red]"
                elif info.disk_used_percent > 80:
                    disk = f"[yellow]{disk}[/yellow]"
            else:
                disk = "-"
            
            row = [
                f"[bold]{name}[/bold]",
                status,
                nixos_ver,
                info.architecture.replace("-linux", ""),
                last_deploy,
                uptime,
                load,
                mem,
                disk
            ]
            
            if full_mode:
                # Package count
                pkg_count = f"{info.package_count:,}" if info.package_count else "-"
                row.append(pkg_count)
                
                # System size
                if info.system_size_mb:
                    if info.system_size_mb > 1024:
                        size = f"{info.system_size_mb / 1024:.1f}G"
                    else:
                        size = f"{info.system_size_mb:.0f}M"
                    row.append(size)
                else:
                    row.append("-")
            
            table.add_row(*row)
        
        self.console.print(table)
        
        # Network status summary
        self._show_network_status(hosts)
        
        # Show any issues
        self._show_issues(hosts)
    
    def _show_network_status(self, hosts: Dict[str, HostInfo]) -> None:
        """Show network connectivity status."""
        panels = []
        
        for name in ["navi", "bee", "halo", "pi"]:
            if name not in hosts:
                continue
            
            info = hosts[name]
            if not info.online:
                continue
            
            dns_icon = "✓" if info.dns_working else "✗"
            dns_color = "green" if info.dns_working else "red"
            net_icon = "✓" if info.internet_working else "✗"
            net_color = "green" if info.internet_working else "red"
            
            # Tailscale status
            ts_status = ""
            if info.tailscale_status:
                if info.tailscale_status == "Running":
                    ts_color = "green"
                    ts_icon = "✓"
                    if info.tailscale_ip:
                        ts_status = f"\nTS: [{ts_color}]{ts_icon} {info.tailscale_ip}[/{ts_color}]"
                    else:
                        ts_status = f"\nTS: [{ts_color}]{ts_icon}[/{ts_color}]"
                elif info.tailscale_status == "not installed":
                    ts_status = "\nTS: [dim]not installed[/dim]"
                else:
                    ts_status = f"\nTS: [yellow]{info.tailscale_status}[/yellow]"
            
            content = f"DNS: [{dns_color}]{dns_icon}[/{dns_color}]  Internet: [{net_color}]{net_icon}[/{net_color}]{ts_status}"
            panels.append(Panel(content, title=name, width=25, box=box.SIMPLE))
        
        if panels:
            self.console.print()
            self.console.print("Network Status:")
            self.console.print(Columns(panels))
    
    def _show_issues(self, hosts: Dict[str, HostInfo]) -> None:
        """Show any detected issues."""
        issues = []
        
        for name, info in hosts.items():
            if not info.online:
                issues.append(f"[red]• {name} is offline[/red]")
            else:
                if info.memory_used_percent and info.memory_used_percent > 90:
                    issues.append(f"[red]• {name} has high memory usage ({info.memory_used_percent:.0f}%)[/red]")
                elif info.memory_used_percent and info.memory_used_percent > 80:
                    issues.append(f"[yellow]• {name} has elevated memory usage ({info.memory_used_percent:.0f}%)[/yellow]")
                
                if info.disk_used_percent and info.disk_used_percent > 90:
                    issues.append(f"[red]• {name} has high disk usage ({info.disk_used_percent:.0f}%)[/red]")
                elif info.disk_used_percent and info.disk_used_percent > 80:
                    issues.append(f"[yellow]• {name} has elevated disk usage ({info.disk_used_percent:.0f}%)[/yellow]")
                
                if info.dns_working is False:
                    issues.append(f"[red]• {name} has DNS resolution issues[/red]")
                
                if info.internet_working is False:
                    issues.append(f"[yellow]• {name} cannot reach the internet[/yellow]")
                
                # Check if running old NixOS version
                if info.nixos_version and "24.05" in info.nixos_version:
                    issues.append(f"[yellow]• {name} is running an old NixOS version (24.05)[/yellow]")
        
        if issues:
            self.console.print()
            self.console.print("[bold]Issues Detected:[/bold]")
            for issue in issues:
                self.console.print(issue)


async def run_system_info(full_mode: bool = False, json_output: bool = False) -> int:
    """Run system information gathering."""
    console = Console() if not json_output else None
    gatherer = SystemInfoGatherer(console=console)
    
    hosts = ["navi", "bee", "halo", "pi"]
    
    results = await gatherer.gather_all_info(hosts, full_mode)
    
    if json_output:
        # Convert to JSON-serializable format
        output = {}
        for name, info in results.items():
            output[name] = {
                "ip": info.ip,
                "state_version": info.state_version,
                "architecture": info.architecture,
                "online": info.online,
                "ping_ms": info.ping_ms,
                "last_deploy": info.last_deploy.isoformat() if info.last_deploy else None,
                "system_generation_time": info.system_generation_time.isoformat() if info.system_generation_time else None,
                "uptime": info.uptime,
                "load_average": info.load_average,
                "memory_used_percent": info.memory_used_percent,
                "disk_used_percent": info.disk_used_percent,
                "package_count": info.package_count,
                "system_size_mb": info.system_size_mb,
                "dns_working": info.dns_working,
                "internet_working": info.internet_working,
                "kernel_version": info.kernel_version,
                "nixos_version": info.nixos_version,
                "tailscale_status": info.tailscale_status,
                "tailscale_ip": info.tailscale_ip
            }
        print(json.dumps(output, indent=2))
    else:
        reporter = SystemInfoReporter(console)
        reporter.show_summary(results, full_mode)
    
    # Return non-zero if any hosts are offline
    offline_count = sum(1 for info in results.values() if not info.online)
    return 1 if offline_count > 0 else 0