# 🎯 Target — Setup Ambiente Lab

> Lab #01 — Nmap Fundamentals · Prof. Giagnotti · [profgiagnotti.it](https://profgiagnotti.it)

Questa cartella contiene le istruzioni per configurare le macchine virtuali target del lab. Hai **tre opzioni** — scegli quella più adatta al tuo setup.

---

## 📋 Opzioni disponibili

| Opzione | Difficoltà | Costo | Consigliata per |
|---|---|---|---|
| [A — Metasploitable 2](#opzione-a--metasploitable-2) | ⭐ Facile | Gratis | Principianti |
| [B — TryHackMe / HackTheBox](#opzione-b--trybackme--hackthebox) | ⭐ Facile | Gratis/Paid | Chi non vuole VM locali |
| [C — Rete locale reale](#opzione-c--rete-locale-reale) | ⭐⭐ Medio | Gratis | Chi ha più dispositivi |

---

## Opzione A — Metasploitable 2

Metasploitable 2 è una VM Linux **volutamente vulnerabile** — progettata apposta per fare pratica in sicurezza. È la scelta consigliata per questo lab.

### Requisiti

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (gratis) o VMware Player
- ~2 GB di spazio su disco
- ~512 MB RAM

### Download

```
https://sourceforge.net/projects/metasploitable/
```

Scarica il file `.zip`, estrailo — trovi dentro il file `.vmdk` (disco virtuale).

### Configurazione in VirtualBox

**1. Crea nuova VM:**
```
Nome:       Metasploitable2
Tipo:       Linux
Versione:   Ubuntu (32-bit)
RAM:        512 MB (bastano)
Disco:      usa il .vmdk esistente → "Usa un file disco fisso esistente"
```

**2. Configura la rete — IMPORTANTE:**

Vai in `Impostazioni → Rete` della VM e imposta:

```
Scheda 1:  Host-only Adapter  ← consigliato per sicurezza
           oppure
Scheda 1:  NAT Network        ← se vuoi che abbia accesso a internet
```

> ⚠️ **Non usare "Bridged"** — metteresti una macchina vulnerabile sulla tua rete reale.

**3. Avvia la VM:**

Credenziali di default:
```
Username: msfadmin
Password: msfadmin
```

**4. Trova l'IP della VM:**

Dentro la VM digita:
```bash
ifconfig
```
Annota l'IP (es. `192.168.56.101`) — è il tuo target per il lab.

### Verifica che funzioni

Dal tuo PC (non dalla VM), apri il terminale e prova:
```bash
ping 192.168.56.101
```
Se ricevi risposta, la VM è raggiungibile e puoi iniziare il lab.

---

## Opzione B — TryHackMe / HackTheBox

Se non vuoi configurare VM locali, puoi usare piattaforme online che forniscono macchine target già pronte.

### TryHackMe (consigliato per principianti)

1. Registrati su [tryhackme.com](https://tryhackme.com) — piano Free sufficiente
2. Scarica e avvia la **VPN** (file `.ovpn` dalla sezione Access)
3. Connettiti alla VPN:
```bash
sudo openvpn tuo-file.ovpn
```
4. Vai alla room **"Nmap"**:
```
https://tryhackme.com/room/furthernmap
```
5. Avvia la macchina — ti viene assegnato un IP target (es. `10.10.x.x`)
6. Usa quell'IP come target in tutti gli esercizi del lab

### HackTheBox

1. Registrati su [hackthebox.com](https://hackthebox.com)
2. Connettiti alla VPN come sopra
3. Usa una macchina **"Starting Point"** (livello principiante)
4. L'IP target viene mostrato nella dashboard della macchina

---

## Opzione C — Rete locale reale

Se hai altri dispositivi sulla tua rete (smartphone, tablet, altri PC, router, NAS) puoi scansionarli direttamente.

> ⚠️ **Scansiona solo dispositivi tuoi.** Non scansionare mai reti o dispositivi altrui senza autorizzazione esplicita — è illegale.

### Trova la tua subnet

```bash
# Linux / Mac
ip route | grep src
# oppure
ifconfig | grep "inet "

# Output esempio:
# 192.168.1.100  → tuo IP
# subnet: 192.168.1.0/24
```

### Target interessanti da scansionare

```
192.168.1.1     → router (quasi sempre il gateway)
192.168.1.0/24  → tutta la rete (host discovery)
```

### Cosa aspettarsi sul router

Un router casalingo tipico ha queste porte aperte:
```
80/tcp   open  http      → pannello amministrazione web
443/tcp  open  https     → pannello HTTPS (se abilitato)
53/udp   open  dns       → server DNS locale
```

---

## 🛠️ Troubleshooting

**La VM non risponde al ping:**
```bash
# Controlla che la VM sia avviata
# Verifica le impostazioni di rete (deve essere Host-only o NAT Network)
# Dentro la VM controlla l'IP: ifconfig
# Controlla che il firewall della VM non blocchi ICMP:
sudo iptables -F   # dentro Metasploitable
```

**Nmap non trova host sulla rete:**
```bash
# Verifica il tuo IP e subnet
ip a

# Prova a pingare manualmente il target
ping 192.168.56.101

# Se il ping funziona ma nmap non trova l'host:
sudo nmap -sn -PS22,80,443 192.168.56.101  # usa TCP invece di ICMP
```

**VirtualBox non fa partire la VM:**
- Verifica che la virtualizzazione sia abilitata nel BIOS (Intel VT-x / AMD-V)
- Su Windows: disabilita Hyper-V se attivo (`bcdedit /set hypervisorlaunchtype off`)

---

## 📖 Risorse

- 📝 Guida VirtualBox: [virtualbox.org/manual](https://www.virtualbox.org/manual/)
- 🔗 Metasploitable 2 docs: [github.com/rapid7/metasploitable3](https://github.com/rapid7/metasploitable3)

---

*⬅️ [Torna al Lab #01](../README.md)*
