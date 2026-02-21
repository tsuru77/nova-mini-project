#!/bin/bash

# Configuration - Match your topology hostnames
SERVER="h1r1"
GOLD="h1r4"
SILVER="h2r4"
BRONZE="h3r4"
SERVER_IP="10.0.0.1"

echo "============================================"
echo "   SDN Traffic Generator & Evaluator (Bash) "
echo "============================================"

# Helper function to run commands in Mininet namespaces
run_in() {
    local host=$1
    local cmd=$2
    # Find the PID of the shell running for that Mininet host
    local pid=$(ps aux | grep "mininet:$host" | grep -v grep | awk '{print $2}')
    if [ -z "$pid" ]; then
        echo "Error: Host $host not found. Is Mininet running?"
        exit 1
    fi
    mn_exec="mnexec -a $pid $cmd"
    eval $mn_exec
}

echo "[+] Starting iperf servers on $SERVER..."
run_in $SERVER "iperf -s -u -p 5001 > gold_res.txt &"
run_in $SERVER "iperf -s -u -p 5002 > silver_res.txt &"
run_in $SERVER "iperf -s -u -p 5003 > bronze_res.txt &"

echo "[+] Starting Latency Monitoring..."
run_in $GOLD "ping -c 20 $SERVER_IP > gold_ping.txt &"
run_in $BRONZE "ping -c 20 $SERVER_IP > bronze_ping.txt &"

# --- TRAFFIC GENERATION ---
echo "[+] Generating STATIC Traffic (Gold)..."
run_in $GOLD "iperf -c $SERVER_IP -u -p 5001 -b 2M -t 20 &"

echo "[+] Generating BURSTY Traffic (Silver)..."
for i in {1..3}; do
    run_in $SILVER "iperf -c $SERVER_IP -u -p 5002 -b 5M -t 2"
    sleep 3
done &

echo "[+] Generating OSCILLATING Traffic (Bronze)..."
for bw in "500K" "4M" "1M" "5M"; do
    run_in $BRONZE "iperf -c $SERVER_IP -u -p 5003 -b $bw -t 4"
done &

echo "[+] Waiting for patterns to complete..."
sleep 22

# --- ANALYSIS ---
echo -e "\n--- FINAL METRICS ---"

# Extract Throughput
gold_bw=$(grep -oE "[0-9.]+ [KM]bits/sec" gold_res.txt | tail -1)
silver_bw=$(grep -oE "[0-9.]+ [KM]bits/sec" silver_res.txt | tail -1)
bronze_bw=$(grep -oE "[0-9.]+ [KM]bits/sec" bronze_res.txt | tail -1)

# Extract Latency (Avg RTT)
gold_lat=$(awk -F '/' 'END {print $5}' gold_ping.txt)
bronze_lat=$(awk -F '/' 'END {print $5}' bronze_ping.txt)

echo "Throughput (Gold):   $gold_bw"
echo "Throughput (Silver): $silver_bw"
echo "Throughput (Bronze): $bronze_bw"
echo "Latency (Gold Avg):  ${gold_lat}ms"
echo "Latency (Bronze Avg):${bronze_lat}ms"

# Cleanup
killall iperf > /dev/null 2>&1
echo "============================================"