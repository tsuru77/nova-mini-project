# evaluate_metrics.py
import time
import re

import os

from sympy import content

# =============================================================
# REQUIREMENTS
# =============================================================
# Run inside Mininet CLI with:
# mininet> py exec(open('evaluate_metrics.py').read(), {'net': net, '__builtins__': __builtins__})

# net is passed explicitly from Mininet CLI
# =============================================================

# =============================================================
# TRAFFIC LIST CONFIGURATION
# Format: (Flow#, Source Host, Dest IP, Duration_s, Rate, Tool)
# Tool: 'itg' (D-ITG) or 'iperf' (UDP)
# =============================================================
traffic_list = [
    # (1, 'h1r4', 'h1r1', 10, '500K', 'iperf', 'static'),
    # (2, 'h2r4', 'h1r2', 10, '800K', 'itg', 'static'),
    # (3, 'h3r4', 'h1r3', 10, '1.5M', 'itg', 'poisson'),
    # (4, 'h4r4', 'h1r4', 10, '2M', 'itg', 'oscillating')
    # Flow 1 (GOLD): Requests 1M, Reserved 1M. Expected Loss: 0%
    # Best Effort (queue 0) → aggressive traffic, will see drops
    (1, 'h1r4', 'h1r1', 15, '3M', 'itg', 'static'),  
    # Queue 1 / DSCP 26 → guaranteed 200 Kbps → no drops
    (2, 'h2r4', 'h1r1', 15, '150K', 'iperf', 'static'),  
    # Queue 2 / DSCP 34 → guaranteed 500 Kbps → no drops
    (3, 'h3r4', 'h1r1', 15, '400K', 'itg', 'oscillating')  
]

log_dir = "logs"

# Vérifie si le répertoire existe déjà
if not os.path.exists(log_dir):
    os.makedirs(log_dir)


# liste des écouteurs actifs
active_itg_receivers = set()
active_iperf_receivers = set()


# =============================================================
# HELPERS
# =============================================================
def get_itg_rate(rate_str):
    """Convert '1M' or '500K' to D-ITG packets/sec (512B pkts)."""
    numeric = float(re.sub(r'[a-zA-Z]', '', rate_str))
    if 'M' in rate_str.upper():
        bps = numeric * 1_000_000
    else:
        bps = numeric * 1_000
    return int(bps / (512 * 8))

def get_host(name):
    """Get host from Mininet or exit."""
    try:
        return net.get(name)
    except Exception:
        print(f"[!] Host {name} not found.")
        raise SystemExit


def launch_iperf(src_host, det_host, duration, rate, mode):
    dst_ip = det_host.IP()
    log_file = f"{log_dir}/iperf_{src_host.name}_{det_host.name}_{mode}_send.txt"

    cmd = (
        f"iperf -c {dst_ip} -u -b {rate} -t {duration} "
        f"> {log_file} 2>&1 &"
    )
    # f"iperf -c {dst_ip} -u -b {rate} -t {duration} > iperf_flow_{flow_num}.txt &")

    src_host.cmd(cmd)
    # print(f"[+] iperf sender started on {src_host.name}")



def launch_itg(src_host, flow_num, dst_host, duration, rate, mode):
    pkt_rate = get_itg_rate(rate)
    log_file_send = f"{log_dir}/ditg_{src_host.name}_{dst_host.name}_{mode}_send.log"
    # log_file_recv = f"{log_dir}/ditg_{dst_host.name}_{mode}_recv.log"

    dst_ip = dst_host.IP()

    # STATIC (constant bit rate)
    if mode == "static":
        # cmd = f"ITGSend -a {dst_ip} -C {pkt_rate} -t {duration*1000} -l {log_file_send} -x {log_file_recv}"
        cmd = f"ITGSend -a {dst_ip} -C {pkt_rate} -t {duration*1000} -l {log_file_send}"

    # POISSON traffic
    elif mode == "poisson":
        # cmd = f"ITGSend -a {dst_ip} -E {pkt_rate} -t {duration*1000} -l {log_file_send} -x {log_file_recv}"
        cmd = f"ITGSend -a {dst_ip} -E {pkt_rate} -t {duration*1000} -l {log_file_send}"

    # OSCILLATING / BURSTY traffic (ON-OFF)
    elif mode == "oscillating":
        # ON time = 500ms, OFF time = 500ms
        cmd = (
            f"ITGSend -T UDP -a {dst_ip} "
            f"-C {pkt_rate} -c 500 "
            f"-On 500ms -Off 500ms "
            f"-t {duration*1000} "
            # f"-l {log_file_send} -x {log_file_recv}"
            f"-l {log_file_send}"
        )

    else:
        print(f"[!] Unknown mode '{mode}', using static.")
        # cmd = f"ITGSend -a {dst_ip} -C {pkt_rate} -t {duration*1000} -l {log_file_send} -x {log_file_recv}"
        cmd = f"ITGSend -a {dst_ip} -C {pkt_rate} -t {duration*1000} -l {log_file_send}"
    
    # print(cmd)
    src_host.cmd(cmd + " &")
    # output = src_host.cmd(cmd)
    # print(src_host.name + "/cmd: " + cmd)
    # print(output)

# =============================================================
# MAIN FUNCTION
# =============================================================
def run_hybrid_session():

    print("\n" + "="*60)
    print("        Hybrid SDN Traffic Generator & Evaluator")
    print("="*60 + "\n")

    # Use first host as server
    # server_name = 'h1r1'
    # server_host = get_host(server_name)
    # server_ip = server_host.IP()
    # print(f"[+] Server = {server_name} ({server_ip})\n")

    # -----------------------------
    # Cleanup old processes/files
    # -----------------------------
    # server_host.cmd("killall -9 ITGRecv iperf > /dev/null 2>&1")
    # server_host.cmd("rm -f recv_flow_*.log")
    for flow in traffic_list:
        src = get_host(flow[1])
        src.cmd("killall -9 ITGSend iperf > /dev/null 2>&1")
        src.cmd(f"rm -f {log_dir}/*_send.log")
        src.cmd(f"rm -f {log_dir}/*_send.txt")

        dest = get_host(flow[2])
        dest.cmd("killall -9 ITGRecv iperf > /dev/null 2>&1")
        dest.cmd(f"rm -f {log_dir}/*_recv.log")
        dest.cmd(f"rm -f {log_dir}/*_recv.txt")

    time.sleep(1)

    print("[+] Starting receivers...")

    # -----------------------------
    # Launch flows
    # -----------------------------
    print("[+] Launching traffic flows...\n")
    for flow_num, src_name, dst_name, duration, rate, tool, mode in traffic_list:
        dst_host = get_host(dst_name)
        src_host = get_host(src_name)

        dst_ip = dst_host.IP()

        print(f"[+] Flow {flow_num}: {tool.upper()} {src_name} -> {dst_ip} @ {rate}")

        if tool.lower() == 'itg':
            # pkt_rate = get_itg_rate(rate)
            # log_file = f"recv_flow_{flow_num}.log"
            # -----------------------------
            # Start server receivers
            # -----------------------------
            if dst_host.name not in active_itg_receivers:
                # print("adding receiver ITGRecv for " + dst_host.name)
                log_file = f"{log_dir}/ditg_{dst_host.name}_{mode}_recv.log"
                dst_host.cmd(f"ITGRecv -l {log_file} &")
                # dst_host.cmd(f"ITGRecv &")
                active_itg_receivers.add(dst_host.name)
                time.sleep(1)
            launch_itg(src_host, flow_num, dst_host, duration, rate, mode)
            # src_host.cmd(f"ITGSend -a {dst_ip} -C {pkt_rate} -t {duration*1000} -x {log_file} &")
        else:
            # -----------------------------
            # Start server receivers
            # -----------------------------
            if dst_host.name not in active_iperf_receivers:
                # print("adding receiver iperf for " + dst_host.name)
                log_file = f"{log_dir}/iperf_{dst_host.name}_{mode}_recv.txt"
                dst_host.cmd(f"iperf -s -u > {log_file} 2>&1 &")
                active_iperf_receivers.add(dst_host.name)
                time.sleep(1)
            launch_iperf(src_host, dst_host, duration, rate, mode)

    # Wait maximum duration + buffer
    wait_time = max(f[3] for f in traffic_list) + 4
    print(f"\n[+] Waiting {wait_time}s for traffic to finish...\n")
    time.sleep(wait_time)

    # -----------------------------
    # Stop receivers
    # -----------------------------
    print("[+] Stopping receivers...")
    for flow in traffic_list:
        dst = get_host(flow[2])
        # dst.cmd("killall -9 ITGRecv iperf > /dev/null 2>&1")
        dst.cmd("killall ITGRecv iperf")
    # server_host.cmd("killall ITGRecv iperf")

    # -----------------------------
    # Generate reports
    # -----------------------------
    print("\n" + "="*60)
    print("                RESULTS")
    print("="*60 + "\n")

    for flow_num, src_name, dst_name, duration, rate, tool, mode in traffic_list:
        print("\n" + "-"*60)
        print(f"FLOW {flow_num} ({tool.upper()}) - Mode: {mode}")
        print(f"From {src_name } -> {dst_name}")
        print("-"*60)
        dst_host = get_host(dst_name)
        src_host = get_host(src_name)

        if tool.lower() == 'itg':
            if dst_host.name in active_itg_receivers:
                # print("adding receiver ITGRecv for " + dst_host.name)
                log_file = f"{log_dir}/ditg_{dst_host.name}_{mode}_recv.log"
                result = src_host.cmd(f"ITGDec {log_file}")
                active_itg_receivers.remove(dst_host.name)
                if result.strip():
                    file_name = f"{log_dir}/ditg_{dst_host.name}_{mode}_recv.txt"
                    with open(file_name, "w") as file:
                        file.write(result)
                    dst_host.cmd(f"rm -f {log_file}")
                    # print(result)
                else:
                    print("[!] No ITG data found.")
            
            log_file = f"{log_dir}/ditg_{src_host.name}_{dst_host.name}_{mode}_send.log"
            result = src_host.cmd(f"ITGDec {log_file}")
            if result.strip():
                # Open the file in write mode ('w') and write the string
                file_name = f"{log_dir}/ditg_{src_host.name}_{dst_host.name}_{mode}_send.txt"
                with open(file_name, "w") as file:
                    file.write(result)
                src_host.cmd(f"rm -f {log_file}")
                # print(result)
            else:
                print("[!] No ITG data found.")
        # else:
        #     output = src_host.cmd(f"cat iperf_flow_{flow_num}.txt")
        #     bw = re.search(r'(\d+(\.\d+)? [KM]bits/sec)', output)
        #     loss = re.search(r'(\d+)%', output)
        #     print(f"Duration            = {duration} s")
        #     print(f"Average bitrate     = {bw.group(1) if bw else 'N/A'}")
        #     print(f"Packet loss         = {loss.group(1) if loss else '0'} %")
        #     print("[Note: iperf UDP gives limited metrics]")

        print("-"*60)

    print("\n[✓] All flows completed.\n")

# =============================================================
# RUN
# =============================================================
run_hybrid_session()