#!/usr/bin/env bash

echo "NixOS Space Cleanup Script"
echo "=========================="

echo "Initial disk usage:"
df -h / | grep -E "Filesystem|/"

# Capture initial disk usage
INITIAL_USED=$(df --output=used / | tail -n1)
INITIAL_AVAIL=$(df --output=avail / | tail -n1)

echo ""
echo "Starting cleanup..."

echo "Removing generations older than 7 days..."
STEP1_USED=$(df --output=used / | tail -n1)
START1_TIME=$(date +%s)
sudo nix-collect-garbage --delete-older-than 7d
END1_TIME=$(date +%s)
NEW1_USED=$(df --output=used / | tail -n1)
STEP1_FREED=$((STEP1_USED - NEW1_USED))
DURATION1=$((END1_TIME - START1_TIME))

echo "Optimizing nix store..."
STEP2_USED=$(df --output=used / | tail -n1)
START2_TIME=$(date +%s)
sudo nix-store --optimise
END2_TIME=$(date +%s)
NEW2_USED=$(df --output=used / | tail -n1)
STEP2_FREED=$((STEP2_USED - NEW2_USED))
DURATION2=$((END2_TIME - START2_TIME))

echo "Cleaning build cache..."
STEP3_USED=$(df --output=used / | tail -n1)
START3_TIME=$(date +%s)
nix-store --gc
END3_TIME=$(date +%s)
NEW3_USED=$(df --output=used / | tail -n1)
STEP3_FREED=$((STEP3_USED - NEW3_USED))
DURATION3=$((END3_TIME - START3_TIME))

echo "Removing old user profile generations..."
STEP4_USED=$(df --output=used / | tail -n1)
START4_TIME=$(date +%s)
nix-env --delete-generations old
END4_TIME=$(date +%s)
NEW4_USED=$(df --output=used / | tail -n1)
STEP4_FREED=$((STEP4_USED - NEW4_USED))
DURATION4=$((END4_TIME - START4_TIME))

echo ""
echo "Cleanup complete!"
echo "================="

# Capture final disk usage
FINAL_USED=$(df --output=used / | tail -n1)
FINAL_AVAIL=$(df --output=avail / | tail -n1)

# Calculate space freed
SPACE_FREED=$((INITIAL_USED - FINAL_USED))
SPACE_GAINED=$((FINAL_AVAIL - INITIAL_AVAIL))

echo "Final disk usage:"
df -h / | grep -E "Filesystem|/"

echo ""
echo "Command Statistics:"
echo "==================="
# Function to format bytes with sign handling
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 0 ]; then
        echo "-$(numfmt --to=iec --suffix=B $((-bytes * 1024)))"
    else
        numfmt --to=iec --suffix=B $((bytes * 1024))
    fi
}

printf "%-35s %5ds  %10s\n" "1. Garbage collection (7d):" "$DURATION1" "$(format_bytes $STEP1_FREED)"
printf "%-35s %5ds  %10s\n" "2. Store optimization:" "$DURATION2" "$(format_bytes $STEP2_FREED)"
printf "%-35s %5ds  %10s\n" "3. Build cache cleanup:" "$DURATION3" "$(format_bytes $STEP3_FREED)"
printf "%-35s %5ds  %10s\n" "4. Profile generation cleanup:" "$DURATION4" "$(format_bytes $STEP4_FREED)"
echo ""
echo "Overall Statistics:"
echo "==================="
echo "  Total space freed: $(format_bytes $SPACE_FREED)"
echo "  Available space gained: $(format_bytes $SPACE_GAINED)"
echo "  Total duration: $((DURATION1 + DURATION2 + DURATION3 + DURATION4)) seconds"

if [ $SPACE_FREED -gt 0 ]; then
    echo "  Success! Freed up disk space."
else
    echo "  No space was freed (already clean)."
fi