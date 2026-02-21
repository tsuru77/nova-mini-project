#!/bin/bash
# ============================================
# Traffic Generator Script
# Usage: ./generate_traffic.sh DEST_IP
# ============================================

DEST=$1

if [ -z "$DEST" ]; then
  echo "Usage: $0 DEST_IP"
  exit 1
fi

mkdir -p results

echo "=== Traffic Generation to $DEST ==="

echo "[1] Ping latency test"
ping -c 50 $DEST > results/ping.txt

echo "[2] Static TCP traffic (10 Mbps)"
iperf -c $DEST -t 30 -b 10M > results/static_tcp.txt

echo "[3] Static UDP traffic"
iperf -c $DEST -u -t 30 -b 5M > results/static_udp.txt

echo "[4] Bursty traffic"
for i in {1..8}
do
  iperf -c $DEST -t 3 -b 40M >> results/bursty.txt
  sleep 2
done

echo "[5] Oscillating traffic"
for rate in 1M 20M 5M 30M 2M 15M
do
  echo "Rate $rate" >> results/oscillating.txt
  iperf -c $DEST -t 8 -b $rate >> results/oscillating.txt
done

echo "Traffic generation complete"
echo "Results stored in ./results/"