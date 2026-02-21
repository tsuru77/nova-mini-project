#!/bin/bash
# ============================================
# SDN QoS Setup - Host-Based Classes of Service
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${YELLOW}Step 1: Configuring OVSDB addresses...${NC}"
s1_URL="http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr"
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1_URL" > /dev/null
echo -e "  Switch s1:   ${GREEN}OK${NC}"
echo ""

echo -e "${YELLOW}Step 2: Creating QoS queues on s1...${NC}"
s1_queue_URL="http://localhost:8080/qos/queue/0000000000000001"

# Queue 0: Bronze (Max 300K), Queue 1: Gold (Min 800K), Queue 2: Silver (Min 500K)
curl -s -X POST -d '{
    "port_name": "s1-eth1", 
    "type": "linux-htb", 
    "max_rate": "2000000", 
    "queues": [
        {"max_rate": "300000"}, 
        {"min_rate": "800000"},
        {"min_rate": "500000"}
    ]
}' "$s1_queue_URL" > /dev/null
echo -e "  Switch s1 Queues: ${GREEN}Created${NC}"
echo ""

echo -e "${YELLOW}Step 3: Installing Host-Based QoS flow rules...${NC}"
s1_flow_URL="http://localhost:8080/qos/rules/0000000000000001"

# 1. Gold Rule (Queue 1): Host 2 (10.0.0.2) to Host 1 (10.0.0.1)
curl -s -X POST -d '{"match": {"nw_src": "10.0.0.2", "nw_dst": "10.0.0.1", "nw_proto": "UDP"}, "actions":{"queue": "1"}}' "$s1_flow_URL" > /dev/null
echo -e "  Gold Class (H2 -> H1)   -> Queue 1: ${GREEN}Installed${NC}"

# 2. Silver Rule (Queue 2): Host 3 (10.0.0.3) to Host 1 (10.0.0.1)
curl -s -X POST -d '{"match": {"nw_src": "10.0.0.3", "nw_dst": "10.0.0.1", "nw_proto": "UDP"}, "actions":{"queue": "2"}}' "$s1_flow_URL" > /dev/null
echo -e "  Silver Class (H3 -> H1) -> Queue 2: ${GREEN}Installed${NC}"

# 3. Bronze Rule (Queue 0): Host 4 (10.0.0.4) to Host 1 (10.0.0.1)
curl -s -X POST -d '{"match": {"nw_src": "10.0.0.4", "nw_dst": "10.0.0.1", "nw_proto": "UDP"}, "actions":{"queue": "0"}}' "$s1_flow_URL" > /dev/null
echo -e "  Bronze Class (H4 -> H1) -> Queue 0: ${GREEN}Installed${NC}"
echo ""
echo -e "${GREEN}Configuration Complete!${NC}"