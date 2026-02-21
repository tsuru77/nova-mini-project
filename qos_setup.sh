#!/bin/bash
# ============================================
# SDN QoS Configuration - Host Based Classes
# ============================================

echo "=== SDN QoS Class Configuration ==="

CONTROLLER="http://localhost:8080"

# Change according to your topology DPIDs
SWITCHES=(
"0000000000000001"   # s1
"0000000000000011"   # s1r1
"0000000000000021"   # s1r2
)

echo "[1] Configure OVSDB connection"
for sw in "${SWITCHES[@]}"
do
  curl -s -X PUT -d '"tcp:127.0.0.1:6632"' \
  $CONTROLLER/v1.0/conf/switches/$sw/ovsdb_addr > /dev/null
  echo "Switch $sw ready"
done

echo ""
echo "[2] Create QoS Queues"

# Queue definitions
# Queue 0 = Best effort (1 Mbps max)
# Queue 1 = Assured (5 Mbps min)
# Queue 2 = Premium (10 Mbps min)

for sw in "${SWITCHES[@]}"
do
curl -s -X POST -d '{
  "port_name": "s1-eth1",
  "type": "linux-htb",
  "max_rate": "20000000",
  "queues": [
    {"max_rate": "1000000"},
    {"min_rate": "5000000"},
    {"min_rate": "10000000"}
  ]}' \
$CONTROLLER/qos/queue/$sw > /dev/null

echo "Queues installed on $sw"
done

echo ""
echo "[3] Install Class-of-Service rules"

# Example hosts (adjust to your IPs)
# h1r1 = 10.0.0.1 → Premium
# h2r1 = 10.0.0.2 → Assured
# others → Best effort

for sw in "${SWITCHES[@]}"
do

# PREMIUM: h1r1 → h1r2
curl -s -X POST -d '{
 "match":{"nw_src":"10.0.0.1","nw_dst":"10.0.0.5"},
 "actions":{"queue":"2"}
}' $CONTROLLER/qos/rules/$sw > /dev/null

# ASSURED: h2r1 → h1r2
curl -s -X POST -d '{
 "match":{"nw_src":"10.0.0.2","nw_dst":"10.0.0.5"},
 "actions":{"queue":"1"}
}' $CONTROLLER/qos/rules/$sw > /dev/null

# BEST EFFORT: default
curl -s -X POST -d '{
 "match":{"nw_dst":"10.0.0.5"},
 "actions":{"queue":"0"}
}' $CONTROLLER/qos/rules/$sw > /dev/null

done

echo "QoS rules installed"
echo "Premium → queue 2"
echo "Assured → queue 1"
echo "Best Effort → queue 0"
echo "Done."