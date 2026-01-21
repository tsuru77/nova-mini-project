#!/bin/bash
# ============================================
# SDN QoS Demo Script - Per-Flow QoS
# Run this to set up QoS for your demo
# ============================================

echo "============================================"
echo "   SDN QoS Demo - Per-Flow Configuration   "
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as part of the demo
echo -e "${YELLOW}Step 1: Configuring OVSDB addresses...${NC}"
echo ""

# Switch DPIDs
s1_URL="http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr"
s1r1_URL="http://localhost:8080/v1.0/conf/switches/0000000000000011/ovsdb_addr"
s1r4_URL="http://localhost:8080/v1.0/conf/switches/0000000000000041/ovsdb_addr"

# Set OVSDB addresses
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1_URL" > /dev/null
echo -e "  Switch s1:   ${GREEN}OK${NC}"
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1r1_URL" > /dev/null
echo -e "  Switch s1r1: ${GREEN}OK${NC}"
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1r4_URL" > /dev/null
echo -e "  Switch s1r4: ${GREEN}OK${NC}"
echo ""

# ============================================
echo -e "${YELLOW}Step 2: Creating QoS queues...${NC}"
echo ""
echo "  Queue 0: max_rate = 500 Kbps (Best Effort)"
echo "  Queue 1: min_rate = 800 Kbps (Premium)"
echo ""

s1_queue_URL="http://localhost:8080/qos/queue/0000000000000001"
s1r1_queue_URL="http://localhost:8080/qos/queue/0000000000000011"
s1r4_queue_URL="http://localhost:8080/qos/queue/0000000000000041"

curl -s -X POST -d '{"port_name": "s1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1_queue_URL" > /dev/null
echo -e "  Switch s1:   ${GREEN}Queues created${NC}"
curl -s -X POST -d '{"port_name": "s1r1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1r1_queue_URL" > /dev/null
echo -e "  Switch s1r1: ${GREEN}Queues created${NC}"
curl -s -X POST -d '{"port_name": "s1r4-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1r4_queue_URL" > /dev/null
echo -e "  Switch s1r4: ${GREEN}Queues created${NC}"
echo ""

# ============================================
echo -e "${YELLOW}Step 3: Installing QoS flow rules...${NC}"
echo ""
echo "  Rule: UDP traffic to 10.0.0.1 port 5002 -> Queue 1 (Premium)"
echo ""

s1_flow_URL="http://localhost:8080/qos/rules/0000000000000001"
s1r1_flow_URL="http://localhost:8080/qos/rules/0000000000000011"
s1r4_flow_URL="http://localhost:8080/qos/rules/0000000000000041"

curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1_flow_URL" > /dev/null
echo -e "  Switch s1:   ${GREEN}Rule installed${NC}"
curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1r1_flow_URL" > /dev/null
echo -e "  Switch s1r1: ${GREEN}Rule installed${NC}"
curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1r4_flow_URL" > /dev/null
echo -e "  Switch s1r4: ${GREEN}Rule installed${NC}"
echo ""

# ============================================
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   QoS Configuration Complete!             ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Now run these commands in Mininet CLI:"
echo ""
echo -e "${YELLOW}# Start iperf servers on h1r1:${NC}"
echo "  h1r1 iperf -s -u -p 5001 &"
echo "  h1r1 iperf -s -u -p 5002 &"
echo ""
echo -e "${YELLOW}# Send traffic from h1r4 (1 Mbps each):${NC}"
echo "  h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &"
echo "  h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &"
echo ""
echo -e "${YELLOW}Expected Results:${NC}"
echo "  Port 5001 (Queue 0): ~500 Kbps (capped)"
echo "  Port 5002 (Queue 1): ~800 Kbps (guaranteed)"
echo ""
