#!/bin/bash
# ============================================
# Script QoS pour Docker
# Utilise localhost:8080 (port exposé par Docker)
# ============================================

echo "============================================"
echo "   SDN QoS Demo - Configuration (Docker)   "
echo "============================================"
echo ""

# Vérifier que Ryu répond
if ! curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "ERREUR: Ryu Controller n'est pas accessible sur http://localhost:8080"
    echo "Vérifiez que Ryu est démarré: docker-compose ps"
    exit 1
fi

echo "✓ Ryu Controller est accessible"
echo ""

# Configuration OVSDB
echo "Step 1: Configuration OVSDB..."
s1_URL="http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr"
s1r1_URL="http://localhost:8080/v1.0/conf/switches/0000000000000011/ovsdb_addr"
s1r4_URL="http://localhost:8080/v1.0/conf/switches/0000000000000041/ovsdb_addr"

curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1_URL" > /dev/null && echo "  Switch s1:   OK" || echo "  Switch s1:   ÉCHEC"
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1r1_URL" > /dev/null && echo "  Switch s1r1: OK" || echo "  Switch s1r1: ÉCHEC"
curl -s -X PUT -d '"tcp:127.0.0.1:6632"' "$s1r4_URL" > /dev/null && echo "  Switch s1r4: OK" || echo "  Switch s1r4: ÉCHEC"
echo ""

# Créer les queues
echo "Step 2: Création des queues QoS..."
echo "  Queue 0: max_rate = 500 Kbps (Best Effort)"
echo "  Queue 1: min_rate = 800 Kbps (Premium)"
echo ""

s1_queue_URL="http://localhost:8080/qos/queue/0000000000000001"
s1r1_queue_URL="http://localhost:8080/qos/queue/0000000000000011"
s1r4_queue_URL="http://localhost:8080/qos/queue/0000000000000041"

curl -s -X POST -d '{"port_name": "s1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1_queue_URL" > /dev/null && echo "  Switch s1:   Queues créées" || echo "  Switch s1:   ÉCHEC"
curl -s -X POST -d '{"port_name": "s1r1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1r1_queue_URL" > /dev/null && echo "  Switch s1r1: Queues créées" || echo "  Switch s1r1: ÉCHEC"
curl -s -X POST -d '{"port_name": "s1r4-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' "$s1r4_queue_URL" > /dev/null && echo "  Switch s1r4: Queues créées" || echo "  Switch s1r4: ÉCHEC"
echo ""

# Installer les règles de flux
echo "Step 3: Installation des règles QoS..."
echo "  Règle: UDP traffic vers 10.0.0.1 port 5002 -> Queue 1 (Premium)"
echo ""

s1_flow_URL="http://localhost:8080/qos/rules/0000000000000001"
s1r1_flow_URL="http://localhost:8080/qos/rules/0000000000000011"
s1r4_flow_URL="http://localhost:8080/qos/rules/0000000000000041"

curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1_flow_URL" > /dev/null && echo "  Switch s1:   Règle installée" || echo "  Switch s1:   ÉCHEC"
curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1r1_flow_URL" > /dev/null && echo "  Switch s1r1: Règle installée" || echo "  Switch s1r1: ÉCHEC"
curl -s -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' "$s1r4_flow_URL" > /dev/null && echo "  Switch s1r4: Règle installée" || echo "  Switch s1r4: ÉCHEC"
echo ""

echo "============================================"
echo "   Configuration QoS terminée!             "
echo "============================================"
echo ""
echo "Maintenant, dans Mininet, lancez:"
echo "  h1r1 iperf -s -u -p 5001 &"
echo "  h1r1 iperf -s -u -p 5002 &"
echo "  h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &"
echo "  h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &"
echo ""

