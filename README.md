# Lab #01 — Nmap: Scansione e Fingerprinting di Rete

**Difficoltà:** ⭐ Base
**Tempo stimato:** 45–60 minuti
**Prerequisiti:** Linux/Kali, conoscenza base TCP/IP

---

## 🎯 Obiettivo

Imparare a usare Nmap per scoprire host attivi, identificare
porte aperte e rilevare versioni dei servizi su una rete target.
Alla fine del lab saprai leggere e interpretare l'output di Nmap
e capirai *perché* ogni flag fa quello che fa.

## 📖 Teoria Essenziale

### Come funziona una scansione TCP SYN (-sS)

Nmap invia un pacchetto SYN a ogni porta del target.
Se riceve SYN-ACK → porta aperta (risponde RST, non completa l'handshake).
Se riceve RST → porta chiusa.
Se nessuna risposta → porta filtrata (firewall).

Questo è chiamato **"half-open scan"**: più veloce e meno rumoroso
di una scansione con handshake completo (-sT).

```
Client          Target
  |--- SYN ----->|
  |<-- SYN/ACK --|   Porta APERTA → Nmap manda RST
  |--- RST ----->|

  |--- SYN ----->|
  |<---- RST ----|   Porta CHIUSA

  |--- SYN ----->|   (nessuna risposta) → Porta FILTRATA
```

## 🔬 Laboratorio

### Setup ambiente

```bash
# Verifica che Nmap sia installato
nmap --version

# Se non è installato (Debian/Ubuntu)
sudo apt install nmap -y
```

### Esercizio 1 — Scoperta host sulla rete locale

```bash
# Scansione ping: trova host attivi su 192.168.1.0/24
nmap -sn 192.168.1.0/24

# Cosa significa ogni flag?
# -sn = ping scan (nessuna scansione porte, solo discovery)
```

**Domanda:** quanti host hai trovato? Riesci a identificarli?

### Esercizio 2 — Scansione porte su un target

```bash
# Scansione SYN sulle 1000 porte più comuni
sudo nmap -sS 192.168.1.TARGET

# Scansione completa (tutte le 65535 porte)
sudo nmap -sS -p- 192.168.1.TARGET
```

### Esercizio 3 — Version detection e OS fingerprinting

```bash
# Rileva versioni dei servizi + OS
sudo nmap -sV -O 192.168.1.TARGET

# Output completo in formato XML (utile per parsing)
sudo nmap -sV -oX scan_result.xml 192.168.1.TARGET
```

## ✅ Sfide Bonus

- [ ] Usa `-A` (aggressive scan) e confronta con `-sV -O` separati. Qual è la differenza?
- [ ] Esegui la scansione con e senza `sudo`. Perché ci sono differenze?
- [ ] Leggi il file XML con Python (vedi `nmap_scanner.py`)

---

📖 Guida correlata: [Cybersecurity Academy](https://profgiagnotti.altervista.org/academy/)