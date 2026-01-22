# 🎬 Guide de Démonstration SDN QoS

## Préparation (5 min avant la démo)

### Vérifications préalables
```bash
# Vérifier que OVS tourne
sudo systemctl status openvswitch-switch

# Si arrêté, le démarrer
sudo systemctl start openvswitch-switch
```

---

## Étape 1 : Lancer le Contrôleur Ryu

**Terminal 1:**
```bash
cd ~/sdn_qos
source venv/bin/activate
ryu-manager --verbose ryu_qos_apps/rest_conf_switch.py \
  ryu_qos_apps/qos_simple_switch_13.py ryu_qos_apps/rest_qos.py
```

✅ **Succès**: Tu vois `loading app ryu_qos_apps/...` sans erreur

---

## Étape 2 : Lancer Mininet

**Terminal 2:**
```bash
cd ~/sdn_qos
sudo mn --custom topology/datacenterBasic.py --topo dcbasic \
  --controller remote --switch ovs,protocols=OpenFlow13
```

✅ **Succès**: Le prompt `mininet>` apparaît

**Dans Mininet, activer OVSDB:**
```bash
mininet> sh ovs-vsctl set-manager ptcp:6632
```

---

## Étape 3 : Configurer la QoS

**Terminal 3:**
```bash
cd ~/sdn_qos/scripts
./demo_script.sh
```

✅ **Succès**: Tu dois voir :
- `Premium (Port 5002) -> Queue 1: Installed`
- `Best Effort (Port 5001) -> Queue 0: Installed`

---

## Étape 4 : Démonstration (2 min)

### Dans Mininet (Terminal 2):

```bash
# 1. Vérifier la topologie
mininet> nodes
mininet> net

# 2. Test de connectivité
mininet> pingall

# 3. Démarrer les serveurs iperf sur h1r1
mininet> h1r1 iperf -s -u -p 5001 &
mininet> h1r1 iperf -s -u -p 5002 &

# 4. Lancer le trafic depuis h1r4 (1 Mbps chacun)
mininet> h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &
mininet> h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &
```

### Résultats attendus (après 10 secondes):

| Port | Queue | Bande passante |
|------|-------|----------------|
| 5001 | Queue 0 (Best Effort) | **~500 Kbps** (plafonné) |
| 5002 | Queue 1 (Premium) | **~800 Kbps** (garanti) |

---

## Commandes Utiles

```bash
# Voir les règles QoS installées
curl http://localhost:8080/qos/rules/0000000000000001

# Voir les queues configurées
curl http://localhost:8080/qos/queue/0000000000000001

# Voir les flows dans le switch
sudo ovs-ofctl dump-flows s1 -O OpenFlow13
```

---

## 🚨 En cas de problème

### Mininet ne démarre pas
```bash
sudo mn -c  # Nettoyer les anciennes sessions
sudo systemctl restart openvswitch-switch
```

### Ryu n'est pas accessible
```bash
# Vérifier que Ryu écoute sur le port 8080
curl http://localhost:8080
```

### Pas de connectivité (pingall échoue)
```bash
# Vérifier que le contrôleur est bien connecté
# Dans les logs Ryu, tu dois voir "connected socket"
```

---

## Nettoyage (après la démo)

```bash
# Dans Mininet
mininet> exit

# Nettoyer
sudo mn -c
```
