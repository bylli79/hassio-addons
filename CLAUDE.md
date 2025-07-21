# Home Assistant Add-on: Hassio Hotspot con DHCPv6

## Panoramica del Progetto

Questo è un add-on per Home Assistant che trasforma il sistema in un access point WiFi con supporto dual-stack DHCPv4/DHCPv6. L'add-on è basato su `dnsmasq` per il servizio DHCP e `hostapd` per l'access point.

### Struttura del Progetto

```
hassio-addons/
├── hassio-hotspot/
│   ├── Dockerfile          # Container definition con dnsmasq
│   ├── config.json         # Configurazione add-on e schema
│   ├── hostapd.conf        # Template hostapd
│   ├── run.sh              # Script principale
│   ├── README.md           # Documentazione
│   └── CHANGELOG.md        # Versioning
├── linux-router/           # Add-on alternativo
└── repository.json         # Repository metadata
```

## Configurazione di Rete

### IPv4 (192.168.99.x)
- **Gateway/Router**: `192.168.99.1` (Raspberry Pi 4 con Home Assistant)
- **Range DHCP**: `192.168.99.100` - `192.168.99.200`
- **Netmask**: `255.255.255.0`
- **Broadcast**: `192.168.99.254`

### IPv6 (fd00:192:168:99::/64)
- **Gateway IPv6**: `fd00:192:168:99::1`
- **Range DHCPv6**: `fd00:192:168:99::100` - `fd00:192:168:99::200`
- **DNS IPv6**: `2001:4860:4860::8888` (Google DNS)

## Configurazione Home Assistant

### 1. Installazione Add-on

1. **Da Repository Locale**:
   - Andare in **Supervisor** > **Add-on Store**
   - Cliccare sui tre puntini > **Repositories**
   - Aggiungere: `https://github.com/username/hassio-addons`
   - Installare "Hassio Hotspot"

2. **Da Repository Personalizzato**:
   - Copiare la cartella `hassio-hotspot` in `/config/addons/`
   - Riavviare Home Assistant
   - L'add-on apparirà in **Local add-ons**

### 2. Configurazione dell'Add-on

```json
{
  "ssid": "HomeAssistant-AP",
  "wpa_passphrase": "your-password",
  "channel": "6",
  "address": "192.168.99.1",
  "netmask": "255.255.255.0",
  "broadcast": "192.168.99.254",
  "interface": "wlan1",
  "internet_interface": "eth0",
  "allow_internet": true,
  "dhcp_enable": true,
  "dhcp_start": "192.168.99.100",
  "dhcp_end": "192.168.99.200",
  "dhcp_dns": "1.1.1.1",
  "dhcp_subnet": "255.255.255.0",
  "dhcp_router": "192.168.99.1",
  "dhcpv6_enable": true,
  "dhcpv6_prefix": "fd00:192:168:99::/64",
  "dhcpv6_start": "fd00:192:168:99::100",
  "dhcpv6_end": "fd00:192:168:99::200",
  "dhcpv6_dns": "2001:4860:4860::8888",
  "hide_ssid": false,
  "lease_time": 864000,
  "static_leases": [
    {
      "mac": "00:11:22:33:44:55",
      "ip": "192.168.99.10",
      "name": "My IoT Device"
    }
  ],
  "static_leases_v6": [
    {
      "mac": "00:11:22:33:44:55",
      "ipv6": "fd00:192:168:99::10",
      "name": "My IoT Device IPv6"
    }
  ]
}
```

### 3. Passi di Configurazione

1. **Identificare l'interfaccia WiFi**:
   - SSH in Home Assistant
   - Eseguire: `ip link show | grep wlan`
   - Annotare il nome dell'interfaccia (es. `wlan1`)

2. **Configurare l'add-on**:
   - Inserire l'interfaccia WiFi nel campo `interface`
   - Configurare SSID e password
   - Selezionare un canale libero (1, 6, 11 per 2.4GHz)

3. **Abilitare i servizi**:
   - `dhcp_enable: true` per DHCPv4
   - `dhcpv6_enable: true` per DHCPv6
   - `allow_internet: true` per condividere la connessione

## Architettura Tecnica

### Componenti Principali

1. **dnsmasq**: Server DHCP dual-stack (sostituisce udhcpd)
2. **hostapd**: Access Point WiFi
3. **iptables/ip6tables**: NAT e forwarding
4. **NetworkManager**: Gestione interfacce

### Flusso di Startup

1. **Validazione**: Controllo variabili e interfacce
2. **Configurazione rete**: Setup IPv4/IPv6 su interfaccia
3. **Firewall**: Configurazione iptables per NAT
4. **Hostapd**: Avvio access point
5. **DHCP**: Avvio dnsmasq con configurazione dual-stack

### File Generati Runtime

- `/hostapd.conf`: Configurazione hostapd
- `/etc/network/interfaces`: Configurazione interfacce
- `/etc/dnsmasq.conf`: Configurazione DHCP dual-stack

## Gestione Repository

### GitHub

1. **Fork del Repository**:
   ```bash
   git clone https://github.com/original/hassio-addons.git
   cd hassio-addons
   git remote add upstream https://github.com/original/hassio-addons.git
   ```

2. **Workflow di Sviluppo**:
   ```bash
   git checkout -b feature/dhcpv6-support
   # Modifiche...
   git add .
   git commit -m "feat: add DHCPv6 support with static leases"
   git push origin feature/dhcpv6-support
   # Creare Pull Request su GitHub
   ```

3. **Aggiornamento da Upstream**:
   ```bash
   git fetch upstream
   git checkout master
   git merge upstream/master
   git push origin master
   ```

### GitLab (Alternativo)

1. **Configurazione GitLab**:
   ```bash
   git remote set-url origin https://gitlab.com/username/hassio-addons.git
   # o aggiungere come remote alternativo:
   git remote add gitlab https://gitlab.com/username/hassio-addons.git
   ```

2. **CI/CD GitLab (.gitlab-ci.yml)**:
   ```yaml
   stages:
     - test
     - build
     - deploy
   
   test:
     stage: test
     script:
       - shellcheck hassio-hotspot/run.sh
       - yamllint hassio-hotspot/config.json
   
   build:
     stage: build
     script:
       - docker build -t hassio-hotspot ./hassio-hotspot/
     only:
       - master
   ```

3. **Mirroring GitHub ↔ GitLab**:
   ```bash
   git remote add github https://github.com/username/hassio-addons.git
   git remote add gitlab https://gitlab.com/username/hassio-addons.git
   git push github master
   git push gitlab master
   ```

## Troubleshooting e Sviluppo

### Comandi Utili

```bash
# Verifica stato add-on
ha addons info hassio-hotspot

# Log dell'add-on
ha addons logs hassio-hotspot

# Test connettività
docker exec -it addon_xxx_hassio_hotspot bash

# Debug interfacce
ip addr show
iwconfig
```

### Testing Locale

```bash
# Build locale
docker build -t hassio-hotspot ./hassio-hotspot/

# Run con mount volumi
docker run -it --privileged --net=host \
  -v /path/to/config.json:/data/options.json \
  hassio-hotspot
```

### Modifiche Comuni

1. **Aggiungere nuova opzione**:
   - Aggiornare `config.json` (options + schema)
   - Modificare `run.sh` per leggere la variabile
   - Testare validazione schema

2. **Debugging DHCP**:
   - Controllare `/etc/dnsmasq.conf` generato
   - Verificare lease in `/var/lib/dhcp/`
   - Monitorare log dnsmasq

3. **Problemi IPv6**:
   - Verificare supporto kernel: `cat /proc/net/if_inet6`
   - Test connettività: `ping6 fd00:192:168:99::1`
   - Router Advertisement: `radvd` se necessario

## Versioning e Release

### Schema Versioning
- **Major**: Cambi incompatibili (es. 1.x → 2.x)
- **Minor**: Nuove funzionalità (es. 1.1 → 1.2)
- **Patch**: Bug fix (es. 1.1.7 → 1.1.8)

### Release Process
1. Aggiornare `version` in `config.json`
2. Aggiornare `CHANGELOG.md`
3. Creare tag Git: `git tag v1.2.0`
4. Push: `git push --tags`

## Contatti e Contributi

- **Repository originale**: https://github.com/joaofl/hassio-addons
- **Documentazione HA**: https://developers.home-assistant.io/docs/add-ons
- **Forum**: https://community.home-assistant.io

### Contribution Guidelines
1. Fork repository
2. Creare feature branch
3. Implementare con test
4. Aggiornare documentazione
5. Sottomettere Pull Request