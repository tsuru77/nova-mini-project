# 🚀 Guide de démarrage rapide

## Installation (une seule fois)

### Option 1: Script automatique (recommandé)
```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos
./install_macos.sh
```

### Option 2: Installation manuelle
Suivez les instructions dans `INSTALL_MACOS.md`

---

## Lancer le projet (pour la démo)

### Étape 1: Terminal 1 - Lancer Ryu Controller

```bash
# Activer l'environnement virtuel
source /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos/venv/bin/activate

# Aller dans le dossier Ryu
cd ~/ryu

# Lancer le contrôleur avec les apps QoS
ryu-manager --verbose \
  ryu/app/rest_conf_switch.py \
  ryu/app/qos_simple_switch_13.py \
  ryu/app/rest_qos.py
```

**✅ Vous devriez voir:** Des logs Ryu qui démarrent, puis "join qos switch" quand Mininet se connecte.

---

### Étape 2: Terminal 2 - Lancer Mininet

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos

# Lancer Mininet avec la topologie datacenter
sudo mn --custom topology/datacenterBasic.py \
  --topo dcbasic \
  --controller remote \
  --switch ovs,protocols=OpenFlow13
```

**Dans le prompt Mininet (`mininet>`), tapez:**

```bash
# Configurer OVSDB (nécessaire pour QoS)
sh ovs-vsctl set-manager ptcp:6632

# Tester la connectivité
pingall
```

**✅ Vous devriez voir:** Tous les hôtes se pingent avec succès.

---

### Étape 3: Terminal 3 - Configurer la QoS

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos/scripts

# Rendre le script exécutable (si nécessaire)
chmod +x perflow_qos_script.sh

# Exécuter le script de configuration QoS
./perflow_qos_script.sh
```

**✅ Vous devriez voir:** 
- "OVSDB addresses configured"
- "Queues created"
- "Rule installed"

---

### Étape 4: Générer le trafic (dans Mininet)

Dans le **Terminal 2** (Mininet CLI), tapez:

```bash
# Démarrer les serveurs iperf sur h1r1
h1r1 iperf -s -u -p 5001 &
h1r1 iperf -s -u -p 5002 &

# Envoyer du trafic depuis h1r4 vers h1r1 (2 flux simultanés)
h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &
h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &
```

**✅ Résultat attendu:**
- **Port 5001** (best effort): ~500 Kbps (limité)
- **Port 5002** (premium): ~800 Kbps (garanti)

---

## Vérifier que tout fonctionne

### Vérifier les queues QoS
```bash
curl http://localhost:8080/qos/queue/0000000000000001
```

### Vérifier les règles de flux
```bash
curl http://localhost:8080/qos/rules/0000000000000001
```

### Voir les flows dans le switch
```bash
sudo ovs-ofctl dump-flows s1 -O OpenFlow13
```

---

## Arrêter le projet

1. **Dans Mininet:** Tapez `exit`
2. **Dans Ryu:** Appuyez sur `Ctrl+C`
3. **Désactiver l'environnement virtuel:** Tapez `deactivate` (optionnel)

---

## Problèmes courants

### "ryu-manager: command not found"
➡️ Assurez-vous que l'environnement virtuel est activé:
```bash
source /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos/venv/bin/activate
```

### "Permission denied" avec Mininet
➡️ Utilisez `sudo` pour lancer Mininet (c'est normal, Mininet a besoin de privilèges root)

### Les switches ne se connectent pas au contrôleur
➡️ Vérifiez que Ryu est lancé AVANT Mininet, et que le contrôleur écoute sur le port 6633

### Les règles QoS ne fonctionnent pas
➡️ Vérifiez que le script `perflow_qos_script.sh` a bien été exécuté après le démarrage de Mininet

---

## Pour la présentation

### Ordre recommandé:
1. **Slide de présentation** (5 min) - Expliquer le projet
2. **Démo** (2 min):
   - Montrer Ryu qui tourne
   - Montrer Mininet lancé
   - Exécuter le script QoS
   - Générer le trafic et montrer la différence de débit

### Points à mettre en avant:
- ✅ **SDN = contrôle centralisé** (Ryu contrôle tous les switches)
- ✅ **QoS programmable** (on configure via REST API)
- ✅ **Résultats visibles** (différence de débit entre les flux)

---

**Bon courage pour ta présentation! 🎓**

