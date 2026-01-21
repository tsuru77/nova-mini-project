# 🌐 SDN QoS Complete Guide
## From Beginner to Demo-Ready in One Document

> **Purpose**: This guide explains everything you need to know about SDN (Software Defined Networking) and QoS (Quality of Service) for your 5-minute presentation and 2-minute demo.

---

## 📚 Table of Contents
1. [What is SDN?](#1-what-is-sdn)
2. [OpenFlow Protocol](#2-openflow-protocol)
3. [Ryu Controller](#3-ryu-controller)
4. [Mininet - Network Emulator](#4-mininet---network-emulator)
5. [Quality of Service (QoS)](#5-quality-of-service-qos)
6. [Project Architecture](#6-project-architecture)
7. [Step-by-Step Demo Guide](#7-step-by-step-demo-guide)
8. [Presentation Script (5 mins)](#8-presentation-script-5-mins)
9. [Common Questions & Answers](#9-common-questions--answers)

---

## 1. What is SDN?

### 🎯 The Simple Explanation
**Traditional Networks**: Every switch/router has its own brain (control logic) built-in. Configuring 100 switches = 100 separate configurations.

**SDN Networks**: One central "brain" (controller) tells all switches what to do. Configuring 100 switches = 1 configuration pushed to all.

### 🔑 Key Concept: Separation of Planes

```
┌─────────────────────────────────────────────────────────────┐
│                     APPLICATION PLANE                        │
│              (Network Apps: QoS, Firewall, LB)              │
├─────────────────────────────────────────────────────────────┤
│                      CONTROL PLANE                           │
│                    (SDN Controller - Ryu)                    │
│         Makes decisions: "Where should this packet go?"      │
├─────────────────────────────────────────────────────────────┤
│                       DATA PLANE                             │
│              (OpenFlow Switches - OVS in Mininet)           │
│         Just forwards packets based on controller's rules    │
└─────────────────────────────────────────────────────────────┘
```

### Why SDN?
| Feature | Traditional | SDN |
|---------|-------------|-----|
| Configuration | Per-device | Centralized |
| Flexibility | Limited | Programmable |
| Network View | Local only | Global view |
| Innovation | Vendor-dependent | Open standards |

---

## 2. OpenFlow Protocol

### 🎯 The Simple Explanation
OpenFlow is the "language" that the SDN controller uses to talk to switches.

### How It Works

```
Controller (Ryu)                    Switch (OVS)
     │                                   │
     │   ←── "I received a new packet,   │
     │        what should I do?"         │
     │       (PACKET_IN message)         │
     │                                   │
     │   "Install this rule and          │
     │    forward to port 2" ──→         │
     │       (FLOW_MOD message)          │
     │                                   │
```

### Flow Tables (The Switch's Memory)
Every OpenFlow switch has a **flow table** - like a decision table:

| Priority | Match (If...) | Action (Then...) |
|----------|---------------|------------------|
| 100 | Destination = 10.0.0.1 | Forward to Port 1 |
| 50 | Any UDP on port 5001 | Send to Queue 1 (high priority) |
| 0 | Everything else | Send to Controller |

### Key OpenFlow Messages
- **PACKET_IN**: Switch asks controller "What do I do with this packet?"
- **FLOW_MOD**: Controller says "Install this rule in your flow table"
- **PACKET_OUT**: Controller says "Forward this specific packet"

---

## 3. Ryu Controller

### 🎯 The Simple Explanation
Ryu is a Python-based SDN controller. It's the "brain" of our network.

### Why Ryu?
- Written in Python (easy to understand)
- Modular - you can add/remove applications
- Has REST API for external control
- Free and open source

### Ryu Architecture

```
┌────────────────────────────────────────────────────┐
│                  RYU CONTROLLER                     │
├────────────────────────────────────────────────────┤
│  Applications (Python files):                       │
│  ┌──────────────────┐  ┌──────────────────┐        │
│  │ simple_switch_13 │  │     rest_qos     │        │
│  │ (L2 forwarding)  │  │ (QoS via REST)   │        │
│  └────────┬─────────┘  └────────┬─────────┘        │
├───────────┴─────────────────────┴──────────────────┤
│              Core (Event handling)                  │
├────────────────────────────────────────────────────┤
│              OpenFlow Protocol Library              │
└────────────────────────────────────────────────────┘
                         │
                    OpenFlow
                         │
                         ▼
                   OVS Switches
```

### Key Files in This Project
```
ryu_qos_apps/
├── qos_simple_switch_13.py  # Layer 2 learning switch + QoS support
├── rest_qos.py              # REST API for QoS configuration
├── rest_conf_switch.py      # REST API for switch configuration
└── simple_switch_13.py      # Basic L2 switch (reference)
```

---

## 4. Mininet - Network Emulator

### 🎯 The Simple Explanation
Mininet lets you create a virtual network with switches, hosts, and links on a single computer.

### Why Mininet?
- No real hardware needed
- Fast to create/destroy networks
- Real Linux networking (not simulation)
- Hosts run real applications (iperf, ping, etc.)

### Our Topology

```
                        ┌─────────────┐
                        │     s1      │ (Root Switch)
                        │ (Core)      │
                        └─────┬───────┘
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
        │   s1r1    │   │   s1r2    │   │   s1r4    │
        │(ToR Rack1)│   │(ToR Rack2)│   │(ToR Rack4)│
        └─────┬─────┘   └─────┬─────┘   └─────┴─────┘
              │               │               │
         ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
         │  h1r1   │    │  h1r2   │    │  h1r4   │
         │10.0.0.1 │    │10.0.0.2 │    │10.0.0.4 │
         └─────────┘    └─────────┘    └─────────┘

Topology: 5 switches, 3+ hosts (configurable up to 16)
```

### Key Topology File
```python
# topology/datacenterBasic.py
class DatacenterBasicTopo(Topo):
    def build(self):
        rootSwitch = self.addSwitch('s1')  # Core switch
        for i in range(1, 4):              # 4 racks
            rack_switch = self.addSwitch('s1r%s' % i)
            self.addLink(rootSwitch, rack_switch)
            for n in range(1, 4):          # Hosts per rack
                host = self.addHost('h%sr%s' % (n, i))
                self.addLink(rack_switch, host)
```

---

## 5. Quality of Service (QoS)

### 🎯 The Simple Explanation
QoS ensures important traffic gets priority. Like a VIP lane at the airport.

### Two QoS Approaches in This Project

#### A) Per-Flow QoS (Match by IP/Port)
```
Rule: "Traffic going to 10.0.0.1 on port 5002 gets HIGH priority"

┌─────────────┐                    ┌─────────────┐
│   Host A    │ ─UDP port 5002──→  │   Host B    │  → Queue 1 (800 Kbps guaranteed)
│             │ ─UDP port 5001──→  │  10.0.0.1   │  → Queue 0 (500 Kbps max)
└─────────────┘                    └─────────────┘
```

#### B) DiffServ QoS (Match by DSCP marking)
```
Rule: "Packets marked with DSCP=26 get medium priority,
       Packets marked with DSCP=34 get high priority"

┌─────────────┐                    ┌─────────────┐
│   Host A    │ ─── DSCP 26 ───→   │   Host B    │  → Queue 1 (200 Kbps min)
│             │ ─── DSCP 34 ───→   │             │  → Queue 2 (500 Kbps min)
└─────────────┘                    └─────────────┘
```

### Queue Configuration
Queues use **HTB (Hierarchical Token Bucket)** for bandwidth control:

```json
{
  "port_name": "s1-eth1",
  "type": "linux-htb",
  "max_rate": "1000000",        // 1 Mbps link capacity
  "queues": [
    {"max_rate": "500000"},     // Queue 0: Best effort (max 500 Kbps)
    {"min_rate": "800000"}      // Queue 1: Premium (guaranteed 800 Kbps)
  ]
}
```

### Classes of Service

| Class | DSCP Value | Priority | Use Case |
|-------|------------|----------|----------|
| Best Effort | 0 | Low | Web browsing, downloads |
| AF31 | 26 | Medium | Business apps |
| AF41 | 34 | High | Video conferencing |
| EF | 46 | Highest | VoIP (real-time) |

---

## 6. Project Architecture

### Complete System Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         REST API Clients                          │
│                  (curl commands / scripts)                        │
└──────────────────────────┬───────────────────────────────────────┘
                           │ HTTP REST (port 8080)
┌──────────────────────────▼───────────────────────────────────────┐
│                       RYU CONTROLLER                              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ qos_simple_switch_13.py + rest_qos.py + rest_conf_switch.py │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬───────────────────────────────────────┘
                           │ OpenFlow (port 6633)
┌──────────────────────────▼───────────────────────────────────────┐
│                     OPEN vSWITCH (OVS)                            │
│                                                                   │
│   ┌───────────────────────────────────────────────────────────┐  │
│   │                    FLOW TABLES                             │  │
│   │  Match: ip_dscp=26  →  Action: set_queue=1, goto_table 1  │  │
│   │  Match: nw_dst=10.0.0.1  →  Action: output:port1          │  │
│   └───────────────────────────────────────────────────────────┘  │
│   ┌───────────────────────────────────────────────────────────┐  │
│   │                    QoS QUEUES (HTB)                        │  │
│   │  Queue 0: max_rate=500Kbps (Best Effort)                  │  │
│   │  Queue 1: min_rate=800Kbps (Premium)                      │  │
│   └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│                       MININET HOSTS                               │
│   h1r1 (10.0.0.1)     h1r2 (10.0.0.2)     h1r4 (10.0.0.4)       │
│   Running: iperf, ping, D-ITG traffic generators                 │
└──────────────────────────────────────────────────────────────────┘
```

### File Structure
```
sdn_qos/
├── ryu_qos_apps/           # Ryu controller applications
│   ├── qos_simple_switch_13.py   # L2 switch with QoS
│   ├── rest_qos.py               # REST API for QoS
│   └── rest_conf_switch.py       # Switch configuration
│
├── topology/               # Mininet topologies
│   └── datacenterBasic.py        # Datacenter topology
│
├── scripts/                # QoS configuration scripts
│   ├── perflow_qos_script.sh     # Per-flow QoS setup
│   └── diffserv_qos_script.sh    # DiffServ QoS setup
│
├── perflow_test_results/   # Test results with iperf
├── diffserv_test_result/   # DiffServ test results
└── demo_results/           # Screenshots and diagrams
```

---

## 7. Step-by-Step Demo Guide

### Prerequisites
- Linux machine (Ubuntu 18.04/20.04 recommended)
- Mininet installed
- Ryu controller installed
- iperf3 installed

### Demo: Per-Flow QoS (2 minutes)

#### Terminal 1: Start Ryu Controller
```bash
# Navigate to ryu directory
cd ryu

# Start controller with QoS apps
ryu-manager --verbose \
  ryu/app/rest_conf_switch.py \
  ryu/app/qos_simple_switch_13.py \
  ryu/app/rest_qos.py
```
**What you'll see**: Controller starts, shows "join qos switch" when switches connect.

#### Terminal 2: Start Mininet
```bash
cd sdn_qos

# Start Mininet with custom topology
sudo mn --custom topology/datacenterBasic.py \
  --topo dcbasic \
  --controller remote \
  --switch ovs,protocols=OpenFlow13

# When Mininet starts, enable OVSDB
mininet> sh ovs-vsctl set-manager ptcp:6632
```
**What you'll see**: Mininet CLI prompt, Controller shows switches connecting.

#### Terminal 3: Configure QoS
```bash
cd sdn_qos/scripts

# Run the QoS configuration script
./perflow_qos_script.sh
```
**What this does**:
1. Connects to OVSDB for queue management
2. Creates queues: Queue 0 (max 500Kbps), Queue 1 (min 800Kbps)
3. Installs flow rules: UDP port 5002 → Queue 1 (premium)

#### Terminal 2 (Mininet): Generate Traffic
```bash
# In Mininet CLI, start iperf server on h1r1
mininet> h1r1 iperf -s -u -p 5001 &
mininet> h1r1 iperf -s -u -p 5002 &

# From h1r4, send traffic to both ports simultaneously
mininet> h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &
mininet> h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &
```

#### Expected Results
- **Port 5001** (Queue 0): ~500 Kbps (capped at max)
- **Port 5002** (Queue 1): ~800 Kbps (guaranteed min bandwidth)

This demonstrates QoS in action - premium traffic gets priority!

---

## 8. Presentation Script (5 mins)

### Slide 1: Introduction (30 seconds)
> "Today I'll present SDN-based Quality of Service management using the Ryu controller. The goal is to demonstrate how we can prioritize different types of network traffic in a programmable way."

### Slide 2: Traditional vs SDN (45 seconds)
> "In traditional networks, each device has its own control logic - making it hard to manage at scale. SDN separates the control plane from the data plane. A central controller makes all decisions, and switches just forward packets. This gives us programmability and a global network view."

### Slide 3: Architecture (1 minute)
> "Our setup uses:
> - **Ryu Controller**: Python-based SDN controller with REST API
> - **Mininet**: Emulates a datacenter with 5 switches and 3+ hosts
> - **Open vSwitch**: Software switch that speaks OpenFlow
> 
> The controller pushes flow rules to switches via OpenFlow, and we configure QoS via REST API."

### Slide 4: QoS Mechanisms (1 minute)
> "We implement two QoS approaches:
> 1. **Per-Flow QoS**: Match traffic by IP address and port, assign to different queues
> 2. **DiffServ**: Mark packets with DSCP values, apply different treatment based on marking
> 
> Each queue has bandwidth guarantees using HTB (Hierarchical Token Bucket)."

### Slide 5: Demo (30 seconds explanation + 2 min demo)
> "Let me demonstrate. I have traffic flowing between two hosts. Before QoS, both flows get equal bandwidth. After applying our QoS rules, premium traffic (port 5002) gets guaranteed 800Kbps while best-effort traffic is limited to 500Kbps."

*[Run demo here]*

### Slide 6: Conclusion (15 seconds)
> "This demonstrates how SDN enables dynamic, programmable QoS management - something very difficult with traditional networking. Questions?"

---

## 9. Common Questions & Answers

### Q1: "What is the advantage of SDN over traditional networking?"
**A**: "Three main advantages:
1. **Centralized control** - one controller manages all switches
2. **Programmability** - we can write applications in Python
3. **Global view** - controller sees entire network state, enabling optimal decisions"

### Q2: "Why did you choose Ryu over other controllers?"
**A**: "Ryu is written in Python, making it easy to develop and debug. It has good documentation, REST API support out of the box, and is widely used in research and education."

### Q3: "How does the QoS actually work at the switch level?"
**A**: "It works in two stages:
1. **Flow matching**: When a packet arrives, the switch checks its flow table for matching rules (by IP, port, DSCP, etc.)
2. **Queue assignment**: Matching packets are placed in a specific queue. Each queue has bandwidth parameters (min/max rate) enforced by the Linux HTB queueing discipline."

### Q4: "What is the difference between per-flow and DiffServ?"
**A**: 
- **Per-flow**: Match using 5-tuple (src IP, dst IP, src port, dst port, protocol). Good for specific applications.
- **DiffServ**: Match using DSCP field in IP header (6 bits). Scalable - don't need rules for every flow, just per-class."

### Q5: "What is DSCP?"
**A**: "Differentiated Services Code Point - a 6-bit field in the IP header used to classify packets into different service classes. For example:
- DSCP 0 = Best Effort
- DSCP 26 (AF31) = Assured Forwarding, medium priority
- DSCP 34 (AF41) = High priority
- DSCP 46 (EF) = Expedited Forwarding, real-time traffic"

### Q6: "Why use Mininet instead of real hardware?"
**A**: "Mininet runs real Linux networking stack, so the behavior is realistic. It's free, requires no hardware, and we can create complex topologies in seconds. For research and demos, it's ideal."

### Q7: "What is HTB?"
**A**: "Hierarchical Token Bucket - a Linux queueing discipline. It uses tokens to control bandwidth:
- Packets consume tokens to be transmitted
- Tokens regenerate at a rate equal to the configured bandwidth
- min_rate guarantees bandwidth, max_rate limits it"

### Q8: "How do you handle network failures in SDN?"
**A**: "The controller can detect failures via OpenFlow events and reroute traffic. In production, we'd have multiple controllers for redundancy."

### Q9: "What happens if the controller goes down?"
**A**: "Switches continue forwarding based on existing flow rules - they become like traditional switches. New flows can't be handled until the controller recovers. This is called 'fail-secure' mode."

### Q10: "What are the performance metrics you measured?"
**A**: "We measured:
- **Throughput**: Bandwidth achieved (using iperf)
- **Latency/Jitter**: Delay and delay variation (using D-ITG)
- **Fairness**: Whether bandwidth allocation matches QoS policy"

---

## 🎯 Quick Reference Card

### Start Everything (Copy-Paste Commands)

```bash
# Terminal 1: Ryu Controller
cd ~/ryu && ryu-manager --verbose ryu/app/rest_conf_switch.py ryu/app/qos_simple_switch_13.py ryu/app/rest_qos.py

# Terminal 2: Mininet
cd ~/sdn_qos && sudo mn --custom topology/datacenterBasic.py --topo dcbasic --controller remote --switch ovs,protocols=OpenFlow13

# In Mininet CLI:
sh ovs-vsctl set-manager ptcp:6632

# Terminal 3: QoS Setup
cd ~/sdn_qos/scripts && ./perflow_qos_script.sh
```

### Useful Commands in Mininet

```bash
# Test connectivity
mininet> pingall

# Check host IPs
mininet> h1r1 ifconfig

# Run command on host
mininet> h1r1 iperf -s -u -p 5001 &

# Open terminal on host
mininet> xterm h1r1

# Exit Mininet
mininet> exit
```

### Check QoS Status

```bash
# Get queue configuration
curl http://localhost:8080/qos/queue/0000000000000001

# Get QoS rules
curl http://localhost:8080/qos/rules/0000000000000001

# Check switch flows
sudo ovs-ofctl dump-flows s1 -O OpenFlow13
```

---

**Good luck with your presentation! 🎓**
