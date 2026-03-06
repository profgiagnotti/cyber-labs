# 📖 Walkthrough — Lab #01 Nmap Fundamentals

> Prof. Giagnotti · [profgiagnotti.it](https://profgiagnotti.it)
> ⚠️ Leggi questo file **solo dopo** aver completato gli esercizi in autonomia.

---

## Indice

- [Esercizio 1 — Host Discovery](#esercizio-1--host-discovery)
- [Esercizio 2 — Scansione Porte](#esercizio-2--scansione-porte)
- [Esercizio 3 — Version Detection e OS Fingerprinting](#esercizio-3--version-detection-e-os-fingerprinting)
- [Sfide Bonus](#sfide-bonus)
- [Errori Comuni](#errori-comuni)
- [Concetti Chiave da Ricordare](#concetti-chiave-da-ricordare)

---

## Esercizio 1 — Host Discovery

### Comando

```bash
sudo nmap -sn 192.168.1.0/24
```

### Output atteso (esempio su rete con Metasploitable)

```
Starting Nmap 7.94 at 2025-01-01 12:00
Nmap scan report for 192.168.56.1
Host is up (0.00042s latency).
MAC Address: 0A:00:27:00:00:00 (VirtualBox)

Nmap scan report for 192.168.56.101
Host is up (0.00087s latency).
MAC Address: 08:00:27:XX:XX:XX (Oracle VirtualBox)

Nmap done: 256 IP addresses (2 hosts up) scanned in 2.15 seconds
```

### Spiegazione dettagliata

Il flag `-sn` (no port scan) istruisce Nmap a fare solo host discovery senza scansionare porte. Nmap usa una combinazione di tecniche per determinare se un host è attivo:

**Con privilegi root (sudo):**
```
1. ARP request  → usato per host sulla stessa rete locale (LAN)
                  ARP è più affidabile di ICMP su reti locali
2. ICMP echo    → ping classico
3. TCP SYN → porta 443
4. TCP ACK → porta 80
```

**Senza privilegi root:**
```
Solo TCP connect su porta 80 e 443
→ meno affidabile, può perdere host con firewall restrittivi
```

**Perché usare `-sn` prima di una scansione completa?**

Scoprire quali host sono attivi prima di scansionare le porte riduce drasticamente i tempi su reti grandi. Su una /24 (256 host) scansionare porte su host inesistenti spreca tempo.

```bash
# Workflow consigliato:
# 1. Prima: scopri host attivi
sudo nmap -sn 192.168.1.0/24 -oG host_attivi.txt

# 2. Poi: scansiona solo gli host trovati
sudo nmap -sS -iL host_attivi.txt
```

### Risposte alle domande di riflessione

**1. Quanti host hai trovato?**
Su una rete casalinga tipica: 3-10 host (router, PC, smartphone, smart TV, ecc.). Su Metasploitable in VirtualBox: 2 host (il gateway VirtualBox + la VM).

**2. Riesci a identificare il router?**
Sì — il router è quasi sempre il primo IP della subnet (`.1`). Nmap spesso mostra anche il MAC address che identifica il produttore (es. `Cisco`, `TP-Link`, `ASUS`).

**3. Vedi il tuo IP nella lista?**
No — Nmap esclude automaticamente il tuo stesso IP dalla lista degli host scoperti. Il tuo IP è la sorgente della scansione, non un target.

---

## Esercizio 2 — Scansione Porte

### Parte A — SYN Scan (top 1000 porte)

```bash
sudo nmap -sS 192.168.56.101
```

### Output atteso su Metasploitable 2

```
Starting Nmap 7.94 at 2025-01-01 12:00
Nmap scan report for 192.168.56.101
Host is up (0.00045s latency).
Not shown: 977 closed tcp ports (reset)

PORT     STATE SERVICE
21/tcp   open  ftp
22/tcp   open  ssh
23/tcp   open  telnet
25/tcp   open  smtp
53/tcp   open  domain
80/tcp   open  http
111/tcp  open  rpcbind
139/tcp  open  netbios-ssn
445/tcp  open  microsoft-ds
512/tcp  open  exec
513/tcp  open  login
514/tcp  open  shell
1099/tcp open  rmiregistry
1524/tcp open  ingreslock
2049/tcp open  nfs
2121/tcp open  ccproxy-ftp
3306/tcp open  mysql
5432/tcp open  postgresql
5900/tcp open  vnc
6000/tcp open  X11
6667/tcp open  irc
8009/tcp open  ajp13
8180/tcp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 0.45 seconds
```

### Spiegazione del SYN Scan

Il SYN scan è chiamato "half-open" perché non completa il three-way handshake TCP:

```
Passo 1:  Client ──── SYN ────────► Server   (porta aperta?)
Passo 2:  Client ◄─── SYN/ACK ──── Server   (risposta: sì, sono aperto)
Passo 3:  Client ──── RST ────────► Server   (reset: non completare)

vs handshake completo:
Passo 1:  Client ──── SYN ────────► Server
Passo 2:  Client ◄─── SYN/ACK ──── Server
Passo 3:  Client ──── ACK ────────► Server   ← questo NON viene inviato nel SYN scan
```

**Vantaggi del SYN scan:**
- Non completa la connessione → meno log nei sistemi target
- Più veloce del TCP Connect scan
- Funziona su tutti i sistemi TCP/IP

**Perché richiede root?**
Il SYN scan richiede la costruzione manuale di pacchetti TCP raw — operazione che il kernel Linux permette solo a root. Senza root, Nmap usa automaticamente il TCP Connect scan (`-sT`) che usa le normali syscall di sistema.

### Analisi dell'output di Metasploitable

Metasploitable 2 ha **molte porte aperte volutamente** — rappresenta un sistema mal configurato e vulnerabile. Alcune porte particolarmente interessanti:

```
21/tcp  ftp       → spesso accetta login anonimo (ftp-anon)
23/tcp  telnet    → protocollo in chiaro, deprecato ⚠️
445/tcp smb       → vulnerabile a EternalBlue se non patchato ⚠️
3306/tcp mysql    → database esposto direttamente su rete ⚠️
5900/tcp vnc      → desktop remoto, spesso con password debole ⚠️
6667/tcp irc      → possibile backdoor IRC bot ⚠️
```

### Parte B — Scansione tutte le porte

```bash
sudo nmap -sS -p- 192.168.56.101
```

Il flag `-p-` è la shorthand per `-p 1-65535`. Scansiona tutte le 65535 porte TCP.

**Perché scansionare tutte le porte?**
I servizi nascosti su porte non standard (es. SSH su porta 2222 invece di 22) non vengono trovati dalla scansione default che copre solo le 1000 porte più comuni. In un penetration test reale, saltare la scansione completa può farti perdere punti di accesso importanti.

```bash
# Versione ottimizzata per velocità su rete locale
sudo nmap -sS -p- -T4 --min-rate 5000 192.168.56.101
```

---

## Esercizio 3 — Version Detection e OS Fingerprinting

### Comando

```bash
sudo nmap -sV -O -T4 192.168.56.101
```

### Output atteso

```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 2.3.4
22/tcp   open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)
23/tcp   open  telnet      Linux telnetd
25/tcp   open  smtp        Postfix smtpd
80/tcp   open  http        Apache httpd 2.2.8 ((Ubuntu) DAV/2)
3306/tcp open  mysql       MySQL 5.0.51a-3ubuntu5
5432/tcp open  postgresql  PostgreSQL DB 8.3.0 - 8.3.7

OS details: Linux 2.6.9 - 2.6.33
Network Distance: 1 hop
```

### Spiegazione Version Detection (-sV)

Nmap determina le versioni dei servizi in due modi:

**1. Banner grabbing** — si connette al servizio e legge il banner che invia spontaneamente:
```
$ nc 192.168.56.101 21
220 (vsFTPd 2.3.4)    ← il servizio annuncia da solo la sua versione
```

**2. Probe attivi** — invia richieste specifiche e analizza le risposte confrontandole con un database di firme (`/usr/share/nmap/nmap-service-probes`).

**Perché le versioni sono importanti?**

Conoscere le versioni ti permette di cercare vulnerabilità note (CVE). Esempio:

```
vsftpd 2.3.4  → CVE-2011-2523 → backdoor nel codice sorgente!
               → porta 6200/tcp si apre dopo login con username che finisce con :)
               → questo è un caso reale, non inventato
```

### Spiegazione OS Detection (-O)

Nmap identifica l'OS analizzando le caratteristiche dello stack TCP/IP — ogni sistema operativo implementa TCP/IP in modo leggermente diverso:

```
Parametri analizzati:
- TTL iniziale (Linux: 64, Windows: 128, Cisco IOS: 255)
- Dimensione finestra TCP
- Flag TCP nelle risposte
- Sequenza ISN (Initial Sequence Number)
- Risposta a probe ICMP non standard
- Opzioni TCP (timestamp, SACK, ecc.)
```

Nmap confronta questi valori con il suo database (`/usr/share/nmap/nmap-os-db`) che contiene migliaia di fingerprint.

> ⚠️ L'OS detection non è sempre precisa al 100% — firewall e dispositivi di rete possono alterare i valori. Usa `--osscan-guess` per forzare un'ipotesi anche quando Nmap non è sicuro.

### Salvataggio output XML e parsing con Python

```bash
# Salva in XML
sudo nmap -sV -oX scan.xml 192.168.56.101

# Analizza con lo script del lab
python3 nmap_scanner.py 192.168.56.101
```

Il file XML contiene tutte le informazioni in formato strutturato — utile per automatizzare la raccolta dati su più host o integrare con altri tool.

---

## Sfide Bonus

### Sfida 1 — Confronto -A vs -sV -O

```bash
# Opzione A — aggressive scan
sudo nmap -A 192.168.56.101

# Opzione B — separati
sudo nmap -sV -O --traceroute 192.168.56.101
```

**Cosa fa `-A` in più rispetto a `-sV -O`?**

`-A` è equivalente a `-sV -O --traceroute -sC`:
- `-sC` esegue gli **script NSE di default** — fa banner grabbing avanzato, identifica configurazioni deboli, controlla certificati SSL, ecc.
- `--traceroute` mostra il percorso di rete verso il target

**Output aggiuntivo tipico di -sC su Metasploitable:**
```
| ftp-anon: Anonymous FTP login allowed   ← FTP anonimo aperto!
| ftp-syst:
|   STAT:
| FTP server status:
|   Connected to 192.168.56.1
|   Logged in as ftp
|_  No session bandwidth limit

| ssh-hostkey:
|   1024 60:0f:cf:e1:c0:5f:6a:74:d6:90:24:fa:c4:d5:6c:cd (DSA)
|_  2048 56:56:24:0f:21:1d:de:a7:2b:ae:61:b1:24:3d:e8:f3 (RSA)

| http-title: Metasploitable2 - Linux
```

### Sfida 2 — Con e senza sudo

```bash
# Senza sudo
nmap -sS 192.168.56.101   # → Warning: SYN scan richiede root, uso -sT
nmap 192.168.56.101       # → usa -sT automaticamente

# Con sudo
sudo nmap -sS 192.168.56.101   # → SYN scan reale
```

**Differenze nei risultati:**
- Senza root: TCP Connect scan — completa il handshake, lascia più log nel target
- Senza root: OS detection non disponibile
- Senza root: alcune tecniche di evasione non disponibili
- Con root: SYN scan, UDP scan, raw packet manipulation

### Sfida 3 — Confronto timing

```bash
# Misura il tempo con il comando time
time sudo nmap -T1 192.168.56.101
time sudo nmap -T3 192.168.56.101
time sudo nmap -T5 192.168.56.101
```

**Risultati tipici su rete locale:**
```
-T1 (Sneaky):    ~45 secondi
-T3 (Normal):    ~1.5 secondi
-T5 (Insane):    ~0.4 secondi
```

**Quando usare quale timing:**
```
-T1 / -T2  → test di penetrazione in produzione, evasione IDS
-T3        → default, bilanciato
-T4        → reti veloci, lab, CTF
-T5        → solo in lab locali — può causare pacchetti persi
```

### Sfida 4 — Parsing XML con Python

```bash
python3 nmap_scanner.py 192.168.56.101
```

Lo script esegue la scansione, salva l'XML e lo analizza mostrando un report formattato con host, porte aperte, servizi e versioni.

### Sfida 5 — UDP Scan

```bash
sudo nmap -sU --top-ports 20 192.168.56.101
```

**Output tipico:**
```
PORT    STATE         SERVICE
53/udp  open          domain
68/udp  open|filtered dhcpc
111/udp open          rpcbind
137/udp open          netbios-ns
```

**Perché UDP è più lento?**

TCP risponde sempre (SYN/ACK o RST) — Nmap sa subito lo stato della porta.
UDP non risponde se la porta è aperta — Nmap deve aspettare il timeout prima di determinare lo stato `open|filtered`. Per 65535 porte questo richiederebbe ore.

---

## Errori Comuni

**"You requested a scan type which requires root privileges"**
```bash
# Soluzione: aggiungi sudo
sudo nmap -sS target
```

**"Note: Host seems down. If it is really up, but blocking our ping probes..."**
```bash
# Il target blocca ICMP — forza la scansione ignorando il ping
sudo nmap -Pn target
# -Pn = tratta l'host come attivo anche se non risponde al ping
```

**"RTTVAR has grown very large, decreasing to 3.0"**
```bash
# La rete è congestionata o il target è lento
# Riduci il timing
sudo nmap -T2 target
```

**OS detection fallita: "No exact OS matches"**
```bash
# Forza un'ipotesi
sudo nmap -O --osscan-guess target
# Oppure aumenta i probe inviati
sudo nmap -O --max-os-tries 5 target
```

**UDP scan troppo lento**
```bash
# Scansiona solo le porte UDP più comuni
sudo nmap -sU --top-ports 100 --open target
# Oppure aumenta la velocità (a rischio di risultati imprecisi)
sudo nmap -sU -T4 --min-rate 1000 target
```

---

## Concetti Chiave da Ricordare

```
┌─────────────────────────────────────────────────────────┐
│  Flag essenziali                                         │
│                                                         │
│  -sn          host discovery (no port scan)             │
│  -sS          SYN scan (richiede root)                  │
│  -sT          TCP Connect scan (no root)                │
│  -sU          UDP scan                                  │
│  -sV          version detection                         │
│  -O           OS detection (richiede root)              │
│  -A           aggressive (-sV -O --traceroute -sC)      │
│  -p-          tutte le 65535 porte                      │
│  -Pn          skip host discovery (tratta come up)      │
│  -T0 / -T5    timing (lento / veloce)                   │
│  -oN/X/G/A    output (normal/xml/grepable/all)          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Stati delle porte                                      │
│                                                         │
│  open          servizio attivo e raggiungibile          │
│  closed        porta raggiungibile, nessun servizio     │
│  filtered      firewall blocca il traffico              │
│  unfiltered    raggiungibile, stato incerto             │
│  open|filtered aperta o filtrata (tipico UDP)           │
└─────────────────────────────────────────────────────────┘
```

---

## Prossimi Passi

Hai completato il Lab #01. I concetti appresi sono la base di ogni attività di ricognizione in cybersecurity.

**Lab #02 — in arrivo:**
```
Wireshark: analisi del traffico generato da Nmap
→ Cosa vede la rete durante una scansione SYN?
→ Come si distingue un SYN scan da un TCP Connect scan?
→ Come rilevare una scansione Nmap con un IDS?
```

---

## Risorse di Approfondimento

- 📝 Articolo completo: [profgiagnotti.it/blog/cybersecurity/nmap-guida-completa](https://profgiagnotti.it)
- 📄 Cheatsheet Nmap: [github.com/profgiagnotti/cheatsheets](https://github.com/profgiagnotti/cheatsheets)
- ▶️ Video walkthrough: [youtube.com/@profgiagnotti](https://youtube.com/@profgiagnotti)
- 💬 Domande: [Discord Prof. Giagnotti](https://discord.gg/profgiagnotti)
- 🔗 Nmap Book (gratuito): [nmap.org/book](https://nmap.org/book/toc.html)
- 🔗 CVE Database: [cve.mitre.org](https://cve.mitre.org)

---

*⬅️ [Torna al Lab #01](../README.md)*
