
#!/usr/bin/env bash

# Network monitoring script that pings 8.8.8.8 every second
# with 5 second timeout and proper error handling

while true; do
    # Use timeout command to ensure ping doesn't hang
    # -c 1: send only one packet
    # -W 5: wait max 5 seconds for response
    if timeout 5s ping -c 1 -W 5 8.8.8.8 > /dev/null 2>&1; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Network OK (8.8.8.8 reachable)"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Network DOWN (8.8.8.8 unreachable)"
    fi
    
    # Wait 1 second before next ping
    sleep 1
done