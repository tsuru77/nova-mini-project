# SDN QoS - Quality of Service with Ryu Controller

Gestion de la Qualité de Service (QoS) dans un réseau SDN utilisant le contrôleur Ryu et Mininet.

## 📋 Prérequis

- **OS**: Ubuntu 20.04+ (VM recommandée)
- **RAM**: 4 Go minimum
- **Droits**: sudo requis

## 🚀 Installation

```bash
# 1. Cloner le repo
git clone <URL_DU_REPO>
cd sdn_qos

# 2. Installer les dépendances système
sudo apt update
sudo apt install -y mininet openvswitch-switch python3-pip iperf3

# 3. Installer Ryu et dépendances Python
pip3 install ryu eventlet==0.30.2

# 4. Vérifier l'installation
sudo mn --test pingall
```

## 📁 Structure du Projet

```
sdn_qos/
├── ryu_qos_apps/          # Applications Ryu (contrôleur)
│   ├── qos_simple_switch_13.py   # Switch L2 avec support QoS
│   ├── rest_qos.py               # API REST pour QoS
│   └── rest_conf_switch.py       # Configuration switches
├── topology/              # Topologies Mininet
│   └── datacenterBasic.py        # Topologie datacenter (5 switches, 3+ hosts)
├── scripts/               # Scripts de configuration QoS
│   ├── perflow_qos_script.sh     # QoS Per-Flow
│   └── diffserv_qos_script.sh    # QoS DiffServ
└── DEMO.md                # Guide de démonstration
```

## ⚡ Démarrage Rapide

### Terminal 1 - Lancer Ryu
```bash
cd sdn_qos
ryu-manager --verbose ryu_qos_apps/rest_conf_switch.py \
  ryu_qos_apps/qos_simple_switch_13.py ryu_qos_apps/rest_qos.py
```

### Terminal 2 - Lancer Mininet
```bash
cd sdn_qos
sudo mn --custom topology/datacenterBasic.py --topo dcbasic \
  --controller remote --switch ovs,protocols=OpenFlow13
```

### Terminal 3 - Configurer QoS
```bash
cd sdn_qos/scripts
./perflow_qos_script.sh
```

## 📖 Documentation

- **[DEMO.md](DEMO.md)** - Guide complet pour la démonstration
- **[SDN_QOS_COMPLETE_GUIDE.md](SDN_QOS_COMPLETE_GUIDE.md)** - Explication détaillée des concepts

## 🎯 Fonctionnalités

- **Per-Flow QoS**: Allocation de bande passante par flux (IP + port)
- **DiffServ QoS**: Classification par marquage DSCP
- **Topologie Datacenter**: 5 switches, 3+ hosts configurables
- **API REST**: Configuration dynamique via HTTP

## 📊 Résultats Attendus

| Méthode | Queue 0 (Best Effort) | Queue 1 (Premium) |
|---------|----------------------|-------------------|
| Per-Flow | ~500 Kbps (max) | ~800 Kbps (garanti) |
