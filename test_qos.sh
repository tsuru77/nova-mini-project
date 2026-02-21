#!/bin/bash
# ============================================================
# SDN QoS Setup Script - Gold/Silver/Bronze Classes
# ============================================================

# Color codes for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Configuring OVSDB addresses for all switches...${NC}"

# List of switch DPIDs
declare -A switches
switches=(
    ["s1"]="0000000000000001"
    ["s1r1"]="0000000000000011"
    ["s1r4"]="0000000000000041"
)

for sw in "${!switches[@]}"; do
    URL="http://localhost:8080/v1.0/conf/switches/${switches[$sw]}/ovsdb_addr"
    curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$URL" > /dev/null
    echo -e "  Switch $sw: ${GREEN}OVSDB OK${NC}"
done
echo ""

# ============================================================
echo -e "${YELLOW}Step 2: Creating QoS queues on all switches...${NC}"

# Queue definitions:
# Queue 0 = Bronze (may drop packets)
# Queue 1 = Silver (medium priority)
# Queue 2 = Gold (guaranteed delivery)
for sw in "${!switches[@]}"; do
    QUEUE_URL="http://localhost:8080/qos/queue/${switches[$sw]}"
    PORT="${sw}-eth1"  # Adjust if needed
    curl -s -X POST -d "{
        \"port_name\": \"$PORT\",
        \"type\": \"linux-htb\",
        \"max_rate\": \"2000000\",
        \"queues\": [
            {\"max_rate\": \"500000\"},           # Bronze
            {\"min_rate\": \"600000\", \"max_rate\": \"1000000\"}, # Silver
            {\"min_rate\": \"1200000\", \"max_rate\": \"2000000\"} # Gold
        ]
    }" "$QUEUE_URL" > /dev/null
    echo -e "  Switch $sw: ${GREEN}Queues created${NC}"
done
echo ""

# ============================================================
echo -e "${YELLOW}Step 3: Installing QoS flow rules...${NC}"

# Flow rules mapping traffic to queues
# Update nw_src / nw_dst according to your Mininet topology
# Format: nw_src = source host, nw_dst = destination host, tp_dst = destination UDP port

declare -A flows
flows=(
    ["gold"]="10.0.0.2"   # h2r4 -> Gold queue
    ["silver"]="10.0.0.3" # h3r4 -> Silver queue
    ["bronze"]="10.0.0.4" # h4r4 -> Bronze queue
)

for sw in "${!switches[@]}"; do
    FLOW_URL="http://localhost:8080/qos/rules/${switches[$sw]}"

    # GOLD
    curl -s -X POST -d "{
        \"match\": {\"nw_src\": \"${flows[gold]}\", \"nw_dst\": \"10.0.0.1\", \"nw_proto\": \"UDP\"},
        \"actions\": {\"queue\": \"2\"}
    }" "$FLOW_URL" > /dev/null

    # SILVER
    curl -s -X POST -d "{
        \"match\": {\"nw_src\": \"${flows[silver]}\", \"nw_dst\": \"10.0.0.1\", \"nw_proto\": \"UDP\"},
        \"actions\": {\"queue\": \"1\"}
    }" "$FLOW_URL" > /dev/null

    # BRONZE
    curl -s -X POST -d "{
        \"match\": {\"nw_src\": \"${flows[bronze]}\", \"nw_dst\": \"10.0.0.1\", \"nw_proto\": \"UDP\"},
        \"actions\": {\"queue\": \"0\"}
    }" "$FLOW_URL" > /dev/null

    echo -e "  Switch $sw: ${GREEN}Flow rules installed${NC}"
done

echo -e "\n${GREEN}QoS setup complete!${NC}"
echo -e "${YELLOW}Gold = guaranteed, Silver = medium, Bronze = best-effort.${NC}\n"