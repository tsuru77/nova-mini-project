#!/usr/bin/env python3
import re
import time
import os
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.topo import Topo

# ==========================================
# 1. Parsing & Math Functions
# ==========================================
def parse_iperf(filename):
    """Extracts bandwidth in Kbits/sec from an iperf server log."""
    if not os.path.exists(filename): return 0.0
    with open(filename, 'r') as f:
        content = f.read()
        match = re.search(r'(\d+(\.\d+)?)\s+([KM])bits/sec', content)
        if match:
            value = float(match.group(1))
            return value * 1000 if match.group(3) == 'M' else value
    return 0.0

def parse_ping(filename):
    """Extracts average latency in ms from a ping log."""
    if not os.path.exists(filename): return 0.0
    with open(filename, 'r') as f:
        content = f.read()
        match = re.search(r'min/avg/max/mdev = [\d\.]+/([\d\.]+)/', content)
        if match: return float(match.group(1))
    return 0.0

def calculate_jains_fairness(throughputs):
    """Calculates Jain's Fairness Index."""
    n = len(throughputs)
    if n == 0 or sum(throughputs) == 0: return 0
    numerator = sum(throughputs) ** 2
    denominator = n * sum([x**2 for x in throughputs])
    return numerator / denominator

# ==========================================
# 2. Traffic Generation & Evaluation
# ==========================================
def generate_and_analyze(net):
    info("\n[+] Starting Traffic Generation...\n")
    
    # Get host objects from the Mininet network
    h1 = net.get('h1') # Server
    h2 = net.get('h2') # Gold Client
    h3 = net.get('h3') # Silver Client
    h4 = net.get('h4') # Bronze Client

    # Start iperf servers in the background on h1
    info("    Starting iperf servers on h1...\n")
    h1.cmd('iperf -s -u -p 5001 > h1_gold.txt &')
    h1.cmd('iperf -s -u -p 5002 > h1_silver.txt &')
    h1.cmd('iperf -s -u -p 5003 > h1_bronze.txt &')

    # Blast traffic from clients simultaneously (simulating congestion)
    info("    Blasting traffic from clients for 10 seconds...\n")
    h2.cmd('iperf -c 10.0.0.1 -u -p 5001 -b 2M -t 10 &')
    h3.cmd('iperf -c 10.0.0.1 -u -p 5002 -b 2M -t 10 &')
    h4.cmd('iperf -c 10.0.0.1 -u -p 5003 -b 2M -t 10 &')

    # Run ping tests for latency
    h2.cmd('ping -c 10 10.0.0.1 > h2_ping.txt &')
    h4.cmd('ping -c 10 10.0.0.1 > h4_ping.txt &')

    # Wait for the tests to finish
    info("    Waiting for tests to complete...\n")
    time.sleep(12) 

    # Cleanup leftover iperf processes
    h1.cmd('killall -9 iperf')

    info("\n[+] Analyzing Metrics...\n")
    gold_bw = parse_iperf("h1_gold.txt")
    silver_bw = parse_iperf("h1_silver.txt")
    bronze_bw = parse_iperf("h1_bronze.txt")
    
    gold_lat = parse_ping("h2_ping.txt")
    bronze_lat = parse_ping("h4_ping.txt")
    
    jains_index = calculate_jains_fairness([gold_bw, silver_bw, bronze_bw])

    # Print nicely formatted results
    print("-" * 40)
    print(f"THROUGHPUT:")
    print(f"  Gold (h2):   {gold_bw:.2f} Kbps")
    print(f"  Silver (h3): {silver_bw:.2f} Kbps")
    print(f"  Bronze (h4): {bronze_bw:.2f} Kbps")
    print("-" * 40)
    print(f"LATENCY:")
    print(f"  Gold (h2):   {gold_lat:.2f} ms")
    print(f"  Bronze (h4): {bronze_lat:.2f} ms")
    print("-" * 40)
    print(f"FAIRNESS:")
    print(f"  Jain's Index: {jains_index:.4f} (Scale: 0.0 to 1.0)")
    print("-" * 40)

# ==========================================
# 3. Network Topology & Main Execution
# ==========================================
class SimpleQoSTopo(Topo):
    def build(self):
        s1 = self.addSwitch('s1')
        h1 = self.addHost('h1', ip='10.0.0.1')
        h2 = self.addHost('h2', ip='10.0.0.2')
        h3 = self.addHost('h3', ip='10.0.0.3')
        h4 = self.addHost('h4', ip='10.0.0.4')

        self.addLink(h1, s1)
        self.addLink(h2, s1)
        self.addLink(h3, s1)
        self.addLink(h4, s1)

if __name__ == '__main__':
    setLogLevel('info')
    
    # 1. Start Network and connect to Ryu Controller
    topo = SimpleQoSTopo()
    net = Mininet(topo=topo, controller=lambda name: RemoteController(name, ip='127.0.0.1', port=6653))
    net.start()

    info("\n*** Network started. You have 15 seconds to run your Bash script to add the QoS rules! ***\n")
    time.sleep(15) # Gives you time to execute the Ryu REST API bash script in another terminal

    # 2. Run the traffic and evaluation logic
    generate_and_analyze(net)

    # 3. Stop network
    net.stop()