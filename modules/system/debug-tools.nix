# Network and system debugging tools
# Scripts in /etc/homelab-test/ for quick server-side debugging
# For full testing: just test-services
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../core/hosts.nix) hosts;
in {
  environment.systemPackages = with pkgs; [
    # Network debugging
    nmap # port scanning and network discovery
    arp-scan # ARP scanning and fingerprinting
    tcpdump # packet capture and analysis
    wireshark-cli # packet analysis (tshark)
    mtr # combined traceroute and ping
    traceroute # trace network path
    netcat # network connections and port testing
    socat # advanced network relay
    
    # DNS debugging
    dnsutils # comprehensive DNS tools (dig, nslookup, etc)
    ldns # DNS library tools (drill, etc)
    
    # HTTP/HTTPS debugging
    httpie # modern curl alternative
    websocat # websocket client
    
    # Performance testing
    iperf3 # network performance testing
    speedtest-cli # internet speed testing
    
    # TLS/SSL debugging
    openssl # SSL/TLS tools
    testssl # SSL/TLS server testing
    
    # JSON/YAML processing
    yq # YAML processor
    
    # Process debugging
    strace # system call tracer
    ltrace # library call tracer
  ];

  environment.etc."homelab-test/README.md" = {
    text = ''
      # Homelab Debug Scripts

      Quick server-side diagnostics. For comprehensive testing of all 34+ services, use: `just test-services`

      ## Available Scripts

      **dns-test.sh** - Test DNS resolution
      - Verifies services resolve to ${hosts.bee.tailscaleIp}
      - Tests wildcard DNS (*.home.jeremyk.net)
      - Checks against AdGuard DNS server

      **service-test.sh** - Test service connectivity  
      - HTTPS connectivity for select services
      - Shows HTTP status codes
      - Tests public vs internal access

      **traefik-test.sh** - Query Traefik configuration
      - Lists configured routers from API
      - Requires Tailscale connection
      - Shows first 10 services

      ## When to Use

      These scripts are for quick debugging when SSH'd into a server.
      They only test a few services as examples.

      For complete testing with parallel execution, metrics, and all services:
      ```bash
      # From your desktop:
      cd /home/jeremy/dotfiles
      just test-services
      ```

      ## Common Commands

      ```bash
      # DNS lookup
      dig @${hosts.bee.tailscaleIp} service.home.jeremyk.net

      # Test specific service
      curl -I https://service.home.jeremyk.net

      # Check logs
      journalctl -u traefik -f
      journalctl -u adguardhome -f

      # Network status
      tailscale status
      ss -tlnp
      ```
    '';
  };

  # Create validation scripts
  environment.etc."homelab-test/dns-test.sh" = {
    mode = "0755";
    text = ''
      #!/usr/bin/env bash
      # Quick DNS test - for full testing use: just test-services
      
      echo "🧪 DNS Resolution Test"
      
      # Test .home domain resolution
      echo -e "\nTesting .home domains..."
      for service in traefik adguard nextcloud radarr sonarr plex; do
        echo -n "  $service.home.jeremyk.net: "
        if dig @${hosts.bee.tailscaleIp} "$service.home.jeremyk.net" +short | grep -q "${hosts.bee.tailscaleIp}"; then
          echo "✅"
        else
          echo "❌"
        fi
      done
      
      # Test wildcard resolution
      echo -e "\nTesting wildcard domains..."
      echo -n "  random-$RANDOM.home.jeremyk.net: "
      if dig @${hosts.bee.tailscaleIp} "random-$RANDOM.home.jeremyk.net" +short | grep -q "${hosts.bee.tailscaleIp}"; then
        echo "✅ (wildcard working)"
      else
        echo "❌ (wildcard not working)"
      fi
    '';
  };

  environment.etc."homelab-test/service-test.sh" = {
    mode = "0755";
    text = ''
      #!/usr/bin/env bash
      # Quick connectivity test - for all 34+ services use: just test-services
      
      echo "🔌 Service Connectivity Test"
      
      # Function to test HTTPS service
      test_https() {
        local url=$1
        local name=$2
        echo -n "  $name: "
        
        # First test if we can connect
        if timeout 5 curl -sk "$url" -o /dev/null; then
          # Get status code
          code=$(curl -sk -o /dev/null -w "%{http_code}" "$url")
          case $code in
            200|301|302|401|403) echo "✅ (HTTP $code)" ;;
            *) echo "⚠️  (HTTP $code)" ;;
          esac
        else
          echo "❌ (timeout/connection failed)"
        fi
      }
      
      echo -e "\nPublic services (should be accessible):"
      test_https "https://nextcloud.jeremyk.net" "Nextcloud"
      test_https "https://gitea.jeremyk.net" "Gitea"
      test_https "https://kuma-halo.jeremyk.net" "Uptime Kuma"
      
      echo -e "\nInternal services (should redirect/403 from outside Tailscale):"
      test_https "https://paperless.home.jeremyk.net" "Paperless"
      test_https "https://grist.home.jeremyk.net" "Grist"
      test_https "https://traefik.home.jeremyk.net" "Traefik Dashboard"
      
      echo -e "\nDirect port tests (via Tailscale):"
      echo -n "  AdGuard DNS (53): "
      timeout 2 nc -zv ${hosts.bee.tailscaleIp} 53 &>/dev/null && echo "✅" || echo "❌"
      echo -n "  Traefik HTTP (80): "
      timeout 2 nc -zv ${hosts.bee.tailscaleIp} 80 &>/dev/null && echo "✅" || echo "❌"
      echo -n "  Traefik HTTPS (443): "
      timeout 2 nc -zv ${hosts.bee.tailscaleIp} 443 &>/dev/null && echo "✅" || echo "❌"
    '';
  };

  environment.etc."homelab-test/traefik-test.sh" = {
    mode = "0755";
    text = ''
      #!/usr/bin/env bash
      # Query Traefik API - requires Tailscale connection
      
      echo "🚦 Testing Traefik Configuration"
      echo "================================"
      
      # Check if we're on Tailscale network
      if ip addr show tailscale0 &>/dev/null; then
        echo "✅ On Tailscale network"
        
        # Get Traefik routers
        echo -e "\nFetching Traefik routers..."
        if routers=$(curl -s http://${hosts.bee.tailscaleIp}:9090/api/http/routers 2>/dev/null); then
          count=$(echo "$routers" | jq -r '. | length')
          echo "  Found $count routers configured"
          
          # Show first 10 routers
          echo -e "\n  First 10 routers:"
          echo "$routers" | jq -r '.[0:10][].name' | sed 's/^/    - /'
        else
          echo "  ❌ Could not fetch routers (is Traefik running?)"
        fi
      else
        echo "❌ Not on Tailscale network - limited testing available"
        echo "  Connect to Tailscale for full testing: tailscale up"
      fi
    '';
  };
}