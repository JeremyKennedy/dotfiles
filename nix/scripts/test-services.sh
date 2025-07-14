#!/usr/bin/env bash

# Homelab Services Health Check Script
# Tests all Traefik-managed services for availability and response
# Useful for monitoring and validation both pre and post migration

# No set -e - we want to continue testing even if individual services fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TOTAL_SERVICES=0
TOTAL_INFRASTRUCTURE=0

# Arrays for categorization
declare -a WORKING_SERVICES
declare -a FAILED_SERVICES
declare -a TIMEOUT_SERVICES
declare -a DIRECT_SERVICES
declare -a SWAG_SERVICES
declare -a INFRASTRUCTURE_SERVICES

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

header() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
}

# Helper function for ping tests with stats tracking
ping_test() {
    local name="$1"
    local target="$2"
    local skip_reason="$3"
    
    echo -n "    $name: "
    if [ -n "$skip_reason" ]; then
        info "SKIPPED ($skip_reason)"
        # Don't count skipped tests in stats
    elif timeout 3 ping -c 1 "$target" >/dev/null 2>&1; then
        success "OK"
        WORKING_SERVICES+=("$name")
        INFRASTRUCTURE_SERVICES+=("$name")
    else
        error "UNREACHABLE"
        FAILED_SERVICES+=("$name (ping)")
    fi
}

# Test service availability with detailed response analysis
test_service() {
    local service_name="$1"
    local url="$2"
    local routing_type="$3"
    local timeout="${4:-5}"

    local status_code response_size content_type response_time

    # Perform the test with detailed metrics using separate curl calls
    local status_code response_size response_time response_body
    
    # Test with following redirects first
    local final_status final_body final_size final_time redirect_count
    
    # Get final response after following redirects
    if ! final_status=$(timeout "$timeout" curl -s -k -L -w "%{http_code}" -o /dev/null "$url" 2>/dev/null); then
        error "$service_name: Connection timeout - $url"
        TIMEOUT_SERVICES+=("$service_name ($routing_type)")
        return
    fi
    
    # Get response body after following redirects
    if ! final_body=$(timeout "$timeout" curl -s -k -L "$url" 2>/dev/null); then
        error "$service_name: Failed to get response body - $url"
        TIMEOUT_SERVICES+=("$service_name ($routing_type)")
        return
    fi
    
    # Get redirect count and timing info
    redirect_count=$(timeout "$timeout" curl -s -k -L -w "%{num_redirects}" -o /dev/null "$url" 2>/dev/null || echo "0")
    final_time=$(timeout "$timeout" curl -s -k -L -w "%{time_total}" -o /dev/null "$url" 2>/dev/null || echo "0")
    final_size=$(echo -n "$final_body" | wc -c)
    
    # Use final status and body for analysis
    status_code="$final_status"
    response_body="$final_body"
    response_size="$final_size"
    response_time="$final_time"

    # Extract detailed error information from response
    local error_detail=""
    if echo "$response_body" | grep -q "plain HTTP request was sent to HTTPS port"; then
        error_detail=" (HTTPS/HTTP protocol mismatch - Traefik config issue)"
    elif echo "$response_body" | grep -q -i "Bad Gateway\|502"; then
        error_detail=" (Bad Gateway - backend service unavailable)"
    elif echo "$response_body" | grep -q -i "404\|Not Found"; then
        error_detail=" (Not Found - service not configured or offline)"
    elif echo "$response_body" | grep -q -i "400\|Bad Request"; then
        error_detail=" (Bad Request - invalid configuration)"
    elif echo "$response_body" | grep -q -i "503\|Service Unavailable"; then
        error_detail=" (Service Unavailable - backend down)"
    elif echo "$response_body" | grep -q -i "Connection refused"; then
        error_detail=" (Connection refused - backend not responding)"
    elif echo "$response_body" | grep -q -i "timeout"; then
        error_detail=" (Timeout - backend too slow)"
    elif [[ $response_size -lt 50 ]] && echo "$response_body" | grep -q -E "^[0-9]+$"; then
        error_detail=" (Raw status code - minimal response)"
    elif [[ $response_size -gt 0 ]]; then
        # Show first 100 chars of error response for debugging
        local error_snippet=$(echo "$response_body" | tr -d '\n' | cut -c1-100)
        error_detail=" (Error: ${error_snippet}...)"
    fi

    # Special case: Plex returns 401 with JavaScript redirect (this is normal)
    if [[ $status_code -eq 401 ]] && echo "$response_body" | grep -q "window.location.*web/index.html"; then
        success "$service_name: Working (Plex redirect) [$routing_type] - $url"
        WORKING_SERVICES+=("$service_name")
        if [[ $routing_type == "SWAG" ]]; then
            SWAG_SERVICES+=("$service_name")
        elif [[ $routing_type == "Infrastructure" ]]; then
            INFRASTRUCTURE_SERVICES+=("$service_name")
        else
            DIRECT_SERVICES+=("$service_name")
        fi
        return
    fi

    # Analyze response
    if [[ $status_code -ge 200 && $status_code -lt 400 ]]; then
        # Accept any 2xx response as working (health endpoints often return minimal content)
        local redirect_info=""
        if [[ $redirect_count -gt 0 ]]; then
            redirect_info=" (${redirect_count} redirects)"
        fi
        success "$service_name: ${status_code} (${response_size}B, ${response_time}s)${redirect_info} [$routing_type] - $url"
        WORKING_SERVICES+=("$service_name")
        if [[ $routing_type == "SWAG" ]]; then
            SWAG_SERVICES+=("$service_name")
        elif [[ $routing_type == "Infrastructure" ]]; then
            INFRASTRUCTURE_SERVICES+=("$service_name")
        else
            DIRECT_SERVICES+=("$service_name")
        fi
        return
    elif [[ $status_code -ge 300 && $status_code -lt 400 ]]; then
        info "$service_name: ${status_code} redirect (${response_time}s) [$routing_type] - $url" 
        WORKING_SERVICES+=("$service_name")
        if [[ $routing_type == "SWAG" ]]; then
            SWAG_SERVICES+=("$service_name")
        elif [[ $routing_type == "Infrastructure" ]]; then
            INFRASTRUCTURE_SERVICES+=("$service_name")
        else
            DIRECT_SERVICES+=("$service_name")
        fi
        return
    else
        error "$service_name: HTTP ${status_code} (${response_size}B)${error_detail} [$routing_type] - $url"
        FAILED_SERVICES+=("$service_name ($routing_type) - HTTP $status_code$error_detail")
        return
    fi
}

# Determine service domain and routing
get_service_info() {
    local service_name="$1"
    local service_url="$2"
    local routing_type="Direct"
    local domain_suffix="home.jeremyk.net"

    # Determine routing type based on port
    if [[ $service_url == *":18071"* ]]; then
        routing_type="SWAG"
    fi

    # Check Traefik router config to determine correct domain and URL
    local router_rule test_url
    if router_rule=$(curl -s "http://100.74.102.74:9090/api/http/routers" 2>/dev/null | jq -r ".[] | select(.service == \"${service_name}\") | .rule" 2>/dev/null); then
        # Extract the first Host() from the rule - this is the primary domain
        if [[ $router_rule =~ Host\(\`([^\`]+)\`\) ]]; then
            local primary_domain="${BASH_REMATCH[1]}"
            test_url="https://${primary_domain}"
        else
            # Fallback to building URL from service name
            test_url="https://${service_name}.${domain_suffix}"
        fi
    else
        # Fallback to building URL from service name
        test_url="https://${service_name}.${domain_suffix}"
    fi

    echo "$test_url|$routing_type"
}

# Extract and test all services
test_all_services() {
    header "HOMELAB SERVICES HEALTH CHECK"

    log "Extracting services from Traefik configuration..."

    cd "$REPO_ROOT" || exit 1

    # Get all services from Traefik config (all backends, not just Tower)
    local services_raw
    if ! services_raw=$(timeout 30 nix develop -c bash -c 'nix eval .#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions.http.services --json 2>/dev/null | jq -r "to_entries[] | \"\(.key):\(.value.loadBalancer.servers[0].url)\""' 2>/dev/null); then
        error "Failed to extract services from Traefik configuration"
        exit 1
    fi

    if [ -z "$services_raw" ]; then
        error "No services found in Traefik configuration"
        exit 1
    fi

    # Sort services alphabetically
    local services_sorted
    services_sorted=$(echo "$services_raw" | sort)

    TOTAL_SERVICES=$(echo "$services_sorted" | wc -l)
    log "Testing $TOTAL_SERVICES services..."
    echo ""

    # Test each service
    while IFS=':' read -r service_name service_url; do
        if [ -z "$service_name" ]; then continue; fi

        local service_info
        service_info=$(get_service_info "$service_name" "$service_url")
        IFS='|' read -r test_url routing_type <<<"$service_info"

        test_service "$service_name" "$test_url" "$routing_type"

    done <<<"$services_sorted"
}

# Test infrastructure services
test_infrastructure() {
    header "INFRASTRUCTURE SERVICES"

    log "Testing core infrastructure components..."

    # Direct infrastructure tests (bypassing Traefik)
    echo "  Infrastructure Services:"
    test_service "adguard-direct" "http://100.74.102.74:3000" "Infrastructure"
    test_service "coredns-direct" "http://100.74.102.74:8080/health" "Infrastructure"
    test_service "traefik-dashboard" "https://traefik.home.jeremyk.net/" "Infrastructure"

    echo ""
    echo "  Network Connectivity Tests:"
    ping_test "Router (192.168.1.1)" "192.168.1.1"
    ping_test "Internet (8.8.8.8)" "8.8.8.8"
    
    echo ""
    echo "  Homelab Host Connectivity:"
    ping_test "Bee (192.168.1.245)" "192.168.1.245"
    ping_test "Tower (192.168.1.240)" "192.168.1.240"  
    ping_test "Pi (192.168.1.230)" "192.168.1.230"
    ping_test "Navi (192.168.1.250)" "192.168.1.250"
    ping_test "Halo VPS (46.62.144.212)" "" "firewall blocks ICMP"
    
    echo ""
    echo "  Tailscale Network Tests:"
    ping_test "Bee TS" "bee.sole-bigeye.ts.net"
    ping_test "Tower TS" "tower.sole-bigeye.ts.net"
    ping_test "Pi TS" "pi.sole-bigeye.ts.net"
    ping_test "Navi TS" "navi.sole-bigeye.ts.net"
    ping_test "Halo TS" "halo.sole-bigeye.ts.net"
    
    echo ""
    echo "  DNS Resolution Tests:"
    echo -n "    External DNS (google.com): "
    if timeout 5 dig google.com +short +timeout=3 2>/dev/null | grep -q -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"; then
        success "External DNS OK"
        WORKING_SERVICES+=("External DNS")
        INFRASTRUCTURE_SERVICES+=("External DNS")
    else
        error "External DNS FAILED"
        FAILED_SERVICES+=("External DNS")
    fi
    
    echo -n "    Internal DNS via Bee (hass.home.jeremyk.net): "
    if timeout 5 dig @100.74.102.74 hass.home.jeremyk.net +short +timeout=3 2>/dev/null | grep -q "100.74.102.74"; then
        success "Internal DNS OK"
        WORKING_SERVICES+=("Internal DNS")
        INFRASTRUCTURE_SERVICES+=("Internal DNS")
    else
        error "Internal DNS FAILED"
        FAILED_SERVICES+=("Internal DNS")
    fi
    
    echo -n "    Public domain (plex.jeremyk.net): "
    if timeout 5 dig plex.jeremyk.net +short +timeout=3 2>/dev/null | grep -q -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"; then
        success "Public DNS OK"
        WORKING_SERVICES+=("Public DNS")
        INFRASTRUCTURE_SERVICES+=("Public DNS")
    else
        error "Public DNS FAILED"
        FAILED_SERVICES+=("Public DNS")
    fi
}

# Analyze service patterns and routing
analyze_services() {
    header "SERVICE ANALYSIS"

    local direct_count=${#DIRECT_SERVICES[@]}
    local swag_count=${#SWAG_SERVICES[@]} 
    local infrastructure_count=${#INFRASTRUCTURE_SERVICES[@]}
    local working_count=${#WORKING_SERVICES[@]}
    local failed_count=${#FAILED_SERVICES[@]}
    local timeout_count=${#TIMEOUT_SERVICES[@]}
    
    # Total tests run (includes duplicates like adguard-direct + adguard)
    local total_tests=$((TOTAL_SERVICES + infrastructure_count))

    echo "📊 Overall Health:"
    echo "  • Working: $working_count/$total_tests ($((working_count * 100 / total_tests))%)"
    echo "  • Failed: $failed_count"
    echo "  • Timeouts: $timeout_count"
    echo ""

    echo "🔀 Service Breakdown:"
    echo "  • Traefik Direct: $direct_count services"
    echo "  • Traefik SWAG: $swag_count services" 
    echo "  • Infrastructure: $infrastructure_count services"
    echo "  • Total Traefik: $TOTAL_SERVICES services"
    echo ""

    if [ $failed_count -gt 0 ]; then
        echo "❌ Failed Services:"
        for service in "${FAILED_SERVICES[@]}"; do
            echo "  • $service"
        done
        echo ""
    fi

    if [ $timeout_count -gt 0 ]; then
        echo "⏱️  Timeout Services:"
        for service in "${TIMEOUT_SERVICES[@]}"; do
            echo "  • $service"
        done
        echo ""
    fi

    # Health score
    local health_score
    health_score=$((working_count * 100 / total_tests))

    echo "📡 Network Layer Analysis:"
    # Simple network diagnostics based on common failure patterns  
    if [ $failed_count -gt 5 ]; then
        # Many services failing suggests network layer issues
        echo -n "    Checking network layers... "
        if ! timeout 3 ping -c 1 192.168.1.1 >/dev/null 2>&1; then
            error "LAN issues detected (router unreachable)"
        elif ! timeout 3 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            error "WAN issues detected (internet unreachable)"
        elif ! timeout 5 dig @100.74.102.74 hass.home.jeremyk.net +short +timeout=3 2>/dev/null | grep -q "100.74.102.74"; then
            error "DNS issues detected (internal resolution failing)"
        else
            warning "Service-level issues (network layers OK)"
        fi
    else
        success "Network layers healthy"
    fi
    echo ""

    if [ $health_score -ge 95 ]; then
        success "🟢 Excellent health ($health_score%)"
    elif [ $health_score -ge 85 ]; then
        info "🟡 Good health ($health_score%)"
    elif [ $health_score -ge 70 ]; then
        warning "🟠 Fair health ($health_score%)"
    else
        error "🔴 Poor health ($health_score%)"
    fi
}

# Generate recommendations
generate_recommendations() {
    local failed_count=${#FAILED_SERVICES[@]}
    local timeout_count=${#TIMEOUT_SERVICES[@]}

    if [ $failed_count -eq 0 ] && [ $timeout_count -eq 0 ]; then
        echo ""
        success "🎉 All services healthy! System ready for production use."
        return
    fi

    echo ""
    echo "🔧 Recommendations:"

    if [ $failed_count -gt 5 ]; then
        echo "  • High failure rate - check network connectivity"
        echo "  • Verify Tailscale connection and DNS resolution"
        echo "  • Check if router migration is needed"
    elif [ $failed_count -gt 0 ]; then
        echo "  • Investigate specific service failures"
        echo "  • Check SWAG proxy configuration for failed services"
        echo "  • Verify service containers are running on Tower"
    fi

    if [ ${#TIMEOUT_SERVICES[@]} -gt 0 ]; then
        echo "  • Timeout services may indicate network issues"
        echo "  • Consider increasing timeout values for slow services"
    fi
}

# Test from remote host via SSH
test_from_host() {
    local host="$1"
    local host_ip="$2"
    
    header "TESTING FROM HOST: $host ($host_ip)"
    
    log "Running health check on $host via SSH..."
    
    # Copy script to remote host and run it
    if ssh "$host_ip" "mkdir -p /tmp/health-check" 2>/dev/null; then
        if scp scripts/test-services.sh "$host_ip:/tmp/health-check/" 2>/dev/null; then
            ssh "$host_ip" "cd /tmp/health-check && chmod +x test-services.sh && ./test-services.sh --remote-mode" 2>/dev/null || {
                error "Failed to run health check on $host"
                return 1
            }
        else
            error "Failed to copy script to $host"
            return 1
        fi
    else
        error "Failed to connect to $host"
        return 1
    fi
}

# Main execution
main() {
    local remote_mode=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --remote-mode)
                remote_mode=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--remote-mode] [--from-all-hosts]"
                echo "  --remote-mode: Run in remote mode (internal use)"
                echo "  --from-all-hosts: Test from all available hosts via SSH"
                exit 0
                ;;
            --from-all-hosts)
                log "Testing from all available hosts..."
                
                # Test from bee
                test_from_host "bee" "100.74.102.74"
                
                # Test from halo  
                test_from_host "halo" "46.62.144.212"
                
                # Test locally
                main --remote-mode
                exit 0
                ;;
        esac
    done
    
    # Check if running from correct directory (skip in remote mode)
    if [ "$remote_mode" = false ] && [ ! -f "flake.nix" ]; then
        error "Please run this script from the nix directory (/home/jeremy/dotfiles/nix)"
        exit 1
    fi

    log "Starting homelab services health check..."

    test_infrastructure  
    test_all_services
    analyze_services
    generate_recommendations

    echo ""
    log "Health check completed!"

    # Exit with error code if services are failing
    if [ ${#FAILED_SERVICES[@]} -gt 0 ] || [ ${#TIMEOUT_SERVICES[@]} -gt 0 ]; then
        exit 1
    fi
}

main "$@"
