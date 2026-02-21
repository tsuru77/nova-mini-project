#!/bin/bash
# Traffic generation & metrics for existing Mininet network

# Hosts & flows
# Format: src dst port rate tool
flows=(
    "h1r4 10.0.0.1 5001 500K iperf"   # Bronze
    "h2r4 10.0.0.1 5002 800K itg"     # Silver
    "h3r4 10.0.0.1 5003 1.5M itg"     # Gold
)

echo "====================="
echo "Starting traffic..."
echo "====================="

# Start servers
mnexec h1r1 bash -c "killall ITGRecv iperf; ITGRecv & iperf -s -u &"

sleep 2

# Launch flows
for f in "${flows[@]}"; do
    set -- $f
    src=$1
    dst=$2
    port=$3
    rate=$4
    tool=$5

    echo "[+] $tool traffic: $src -> $dst @ $rate"

    if [ "$tool" == "itg" ]; then
        # Convert rate to packets/sec (512B pkts)
        numeric=$(echo $rate | sed 's/[KM]//')
        if [[ $rate == *M ]]; then
            pkt_rate=$(( numeric * 1000000 / (512*8) ))
        else
            pkt_rate=$(( numeric * 1000 / (512*8) ))
        fi
        mnexec $src bash -c "ITGSend -a $dst -C $pkt_rate -t 10000 -x recv_${src}.dat &"
    else
        mnexec $src bash -c "iperf -c $dst -u -p $port -b $rate -t 10 > iperf_${src}.txt &"
    fi
done

sleep 12

# Stop servers
mnexec h1r1 bash -c "killall ITGRecv iperf"

echo "====================="
echo "Traffic complete."
echo "====================="

# Display iperf results
for f in "${flows[@]}"; do
    set -- $f
    src=$1
    tool=$5
    if [ "$tool" == "iperf" ]; then
        echo "----- $src iperf result -----"
        mnexec $src cat iperf_${src}.txt
    fi
done