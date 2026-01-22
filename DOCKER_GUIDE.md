# 🐳 Guide complet - Exécuter tout le projet avec Docker

## ✅ Avantages de Docker

- ✅ **Pas besoin d'installer Mininet nativement** sur macOS
- ✅ **Pas besoin d'installer Ryu** sur votre Mac
- ✅ **Environnement isolé** et reproductible
- ✅ **Fonctionne sur macOS, Linux et Windows**
- ✅ **Facile à nettoyer** (juste supprimer les conteneurs)

## 📋 Prérequis

1. **Docker Desktop** installé et démarré
   - Télécharger: https://www.docker.com/products/docker-desktop
   - Vérifier: `docker --version`

2. **Git** (pour cloner le projet si nécessaire)

## 🚀 Démarrage rapide

### Option 1: Script automatique (recommandé)

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos
chmod +x run-docker.sh
./run-docker.sh
```

### Option 2: Commandes manuelles

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos

# 1. Démarrer Ryu
docker-compose up -d ryu

# 2. Attendre 10 secondes que Ryu démarre
sleep 10

# 3. Lancer Mininet dans un conteneur interactif
docker-compose run --rm mininet bash
```

## 📝 Étapes détaillées

### Étape 1: Démarrer Ryu Controller

```bash
docker-compose up -d ryu
```

**Vérifier que Ryu fonctionne:**
```bash
curl http://localhost:8080
# Devrait retourner une page HTML ou JSON
```

**Voir les logs:**
```bash
docker logs -f ryu-controller
```

### Étape 2: Lancer Mininet

Dans un **nouveau terminal**:

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos
docker-compose run --rm mininet bash
```

Vous êtes maintenant dans le conteneur Mininet. Exécutez:

```bash
# Lancer la topologie datacenter
mn --custom topology/datacenterBasic.py \
  --topo dcbasic \
  --controller remote,ip=ryu-controller \
  --switch ovs,protocols=OpenFlow13
```

**Important:** Utilisez `ryu-controller` comme IP (nom du service Docker), pas `localhost`!

### Étape 3: Configurer OVSDB dans Mininet

Dans le prompt Mininet (`mininet>`):

```bash
sh ovs-vsctl set-manager ptcp:6632
pingall
```

Vous devriez voir que tous les hôtes se pingent.

### Étape 4: Configurer la QoS

Dans un **nouveau terminal** (sur votre Mac, pas dans le conteneur):

```bash
cd /Users/shaku/Documents/p/RES/M2/NOVA/sdn_qos/scripts
chmod +x perflow_qos_script.sh
./perflow_qos_script.sh
```

**Note:** Le script utilise `localhost:8080` qui fonctionne car Ryu expose le port 8080 sur votre Mac.

### Étape 5: Générer le trafic (dans Mininet)

Dans le conteneur Mininet (Terminal 2), dans le prompt `mininet>`:

```bash
# Démarrer les serveurs iperf
h1r1 iperf -s -u -p 5001 &
h1r1 iperf -s -u -p 5002 &

# Envoyer du trafic
h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &
h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &
```

**Résultat attendu:**
- Port 5001 (best effort): ~500 Kbps
- Port 5002 (premium): ~800 Kbps

## 🛠️ Commandes utiles

### Voir les conteneurs en cours
```bash
docker ps
```

### Voir les logs de Ryu
```bash
docker logs -f ryu-controller
```

### Arrêter tout
```bash
docker-compose down
```

### Nettoyer complètement
```bash
docker-compose down -v
docker system prune -f
```

### Accéder au conteneur Mininet (si déjà lancé)
```bash
docker exec -it mininet-topo bash
```

## 🔧 Dépannage

### Problème: "Cannot connect to ryu-controller"

**Solution:** Vérifiez que Ryu est démarré:
```bash
docker ps | grep ryu
docker logs ryu-controller
```

### Problème: "Permission denied" dans Mininet

**Solution:** Le conteneur Mininet utilise `privileged: true`, cela devrait fonctionner. Si problème persiste:
```bash
docker-compose down
docker-compose run --rm --privileged mininet bash
```

### Problème: Les scripts QoS ne fonctionnent pas

**Solution:** Vérifiez que Ryu répond:
```bash
curl http://localhost:8080/qos/queue/0000000000000001
```

### Problème: Mininet ne peut pas se connecter au contrôleur

**Solution:** Utilisez `ryu-controller` comme IP (nom du service Docker):
```bash
mn --controller remote,ip=ryu-controller ...
```

## 📊 Architecture Docker

```
┌─────────────────────────────────────────┐
│         Votre Mac (macOS)                │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Docker Network (sdn-network)    │  │
│  │                                   │  │
│  │  ┌──────────────┐  ┌──────────┐  │  │
│  │  │ ryu-controller│  │ mininet  │  │  │
│  │  │  Port 8080   │  │ (priv.)  │  │  │
│  │  │  Port 6633   │  │          │  │  │
│  │  └──────┬───────┘  └────┬─────┘  │  │
│  │         │               │        │  │
│  └─────────┼───────────────┼────────┘  │
│            │               │            │
│  ┌─────────▼───────────────▼────────┐  │
│  │  Ports exposés sur votre Mac:    │  │
│  │  - localhost:8080 (REST API)     │  │
│  │  - localhost:6633 (OpenFlow)     │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## 🎯 Pour la présentation

### Ordre recommandé:

1. **Démarrer Ryu** (Terminal 1)
   ```bash
   docker-compose up -d ryu
   docker logs -f ryu-controller
   ```

2. **Lancer Mininet** (Terminal 2)
   ```bash
   docker-compose run --rm mininet bash
   # Puis dans le conteneur:
   mn --custom topology/datacenterBasic.py --topo dcbasic --controller remote,ip=ryu-controller --switch ovs,protocols=OpenFlow13
   ```

3. **Configurer QoS** (Terminal 3)
   ```bash
   cd scripts && ./perflow_qos_script.sh
   ```

4. **Générer le trafic** (dans Mininet)
   ```bash
   h1r1 iperf -s -u -p 5001 &
   h1r1 iperf -s -u -p 5002 &
   h1r4 iperf -c 10.0.0.1 -u -p 5001 -b 1M -t 10 &
   h1r4 iperf -c 10.0.0.1 -u -p 5002 -b 1M -t 10 &
   ```

## ✅ Checklist avant la présentation

- [ ] Docker Desktop est démarré
- [ ] `docker ps` fonctionne
- [ ] Ryu démarre correctement (`docker-compose up -d ryu`)
- [ ] Mininet peut se connecter à Ryu
- [ ] Les scripts QoS fonctionnent
- [ ] Le trafic iperf montre la différence de débit

**Bon courage pour ta présentation! 🎓**

