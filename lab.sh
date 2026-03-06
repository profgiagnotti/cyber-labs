#!/bin/bash
# =============================================================================
# Lab #01 — Nmap Fundamentals
# Prof. Giagnotti · profgiagnotti.it
#
# Questo script configura l'ambiente per il lab e guida
# l'esecuzione degli esercizi passo per passo.
#
# Uso: chmod +x lab.sh && sudo ./lab.sh
# =============================================================================

# ── COLORI ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── FUNZIONI UI ───────────────────────────────────────────────────────────────
banner() {
  echo -e "\n${BLUE}${BOLD}"
  echo "  ██████╗ ██████╗  ██████╗ ███████╗"
  echo "  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝"
  echo "  ██████╔╝██████╔╝██║   ██║█████╗  "
  echo "  ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  "
  echo "  ██║     ██║  ██║╚██████╔╝██║     "
  echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     "
  echo -e "${NC}"
  echo -e "${CYAN}  Prof. Giagnotti · profgiagnotti.it${NC}"
  echo -e "${CYAN}  Lab #01 — Nmap Fundamentals${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────${NC}\n"
}

info()    { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }
step()    { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}\n"; }
prompt()  { echo -e "${YELLOW}[?]${NC} $1"; }

press_enter() {
  echo -e "\n${YELLOW}Premi INVIO per continuare...${NC}"
  read -r
}

# ── CONTROLLI PREREQUISITI ────────────────────────────────────────────────────
check_root() {
  if [[ $EUID -ne 0 ]]; then
    warning "Alcune scansioni (SYN scan -sS) richiedono privilegi root."
    warning "Avvia con: sudo ./lab.sh"
    echo -e "\nVuoi continuare comunque con privilegi limitati? (alcune scansioni non funzioneranno) [s/N]"
    read -r risposta
    if [[ ! "$risposta" =~ ^[Ss]$ ]]; then
      exit 1
    fi
    IS_ROOT=false
  else
    IS_ROOT=true
    success "Privilegi root: OK"
  fi
}

check_nmap() {
  step "Verifica dipendenze"
  if command -v nmap &>/dev/null; then
    NMAP_VERSION=$(nmap --version | head -1)
    success "Nmap trovato: $NMAP_VERSION"
  else
    error "Nmap non trovato. Installazione in corso..."
    if command -v apt &>/dev/null; then
      apt update -qq && apt install -y nmap
    elif command -v yum &>/dev/null; then
      yum install -y nmap
    elif command -v brew &>/dev/null; then
      brew install nmap
    else
      error "Package manager non riconosciuto. Installa Nmap manualmente: https://nmap.org"
      exit 1
    fi
    success "Nmap installato correttamente."
  fi

  # Controlla python3
  if command -v python3 &>/dev/null; then
    success "Python3 trovato: $(python3 --version)"
  else
    warning "Python3 non trovato — lo script nmap_scanner.py non sarà eseguibile."
  fi

  # Controlla wireshark (opzionale)
  if command -v wireshark &>/dev/null || command -v tshark &>/dev/null; then
    success "Wireshark/tshark trovato (utile per analisi traffico)"
  else
    info "Wireshark non trovato (opzionale). Installa con: sudo apt install wireshark"
  fi
}

# ── RILEVAMENTO RETE LOCALE ───────────────────────────────────────────────────
detect_network() {
  step "Rilevamento rete locale"

  # Rileva interfaccia e subnet automaticamente
  if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
    SUBNET=$(ip -o -f inet addr show "$INTERFACE" 2>/dev/null | awk '{print $4}')
  else
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    INTERFACE="eth0"
    SUBNET="${LOCAL_IP%.*}.0/24"
  fi

  info "IP locale rilevato:  ${BOLD}$LOCAL_IP${NC}"
  info "Interfaccia:         ${BOLD}$INTERFACE${NC}"
  info "Subnet:              ${BOLD}$SUBNET${NC}"

  echo -e "\n${YELLOW}Usare questi valori? [S/n]${NC}"
  read -r risposta
  if [[ "$risposta" =~ ^[Nn]$ ]]; then
    echo -e "Inserisci la subnet target (es: 192.168.1.0/24):"
    read -r SUBNET
    echo -e "Inserisci il tuo IP locale:"
    read -r LOCAL_IP
  fi

  success "Rete configurata: $SUBNET"
}

# ── ESERCIZIO 1: HOST DISCOVERY ───────────────────────────────────────────────
esercizio_1() {
  step "Esercizio 1 — Host Discovery (Ping Scan)"

  echo -e "${BOLD}Obiettivo:${NC} scoprire quali host sono attivi sulla rete $SUBNET"
  echo -e "${BOLD}Comando:${NC}   nmap -sn $SUBNET\n"

  echo -e "Il flag ${CYAN}-sn${NC} significa 'no port scan':"
  echo -e "  → Nmap invia ICMP echo + TCP SYN sulla porta 443 + TCP ACK sulla porta 80"
  echo -e "  → Se l'host risponde a uno qualsiasi → è attivo"
  echo -e "  → Non viene scansionata nessuna porta\n"

  press_enter

  info "Esecuzione: nmap -sn $SUBNET"
  echo -e "${BLUE}────────────────────────────────────────${NC}"

  if [[ "$IS_ROOT" == true ]]; then
    nmap -sn "$SUBNET"
  else
    warning "Senza root il ping scan usa solo TCP invece di ICMP+TCP — risultati parziali"
    nmap -sn "$SUBNET"
  fi

  echo -e "${BLUE}────────────────────────────────────────${NC}"

  echo -e "\n${BOLD}Domande di riflessione:${NC}"
  echo -e "  1. Quanti host hai trovato?"
  echo -e "  2. Riesci a identificare il tuo router (spesso il primo IP, es .1)?"
  echo -e "  3. Vedi il tuo stesso IP nella lista?"

  press_enter
}

# ── ESERCIZIO 2: PORT SCAN ────────────────────────────────────────────────────
esercizio_2() {
  step "Esercizio 2 — Scansione Porte (SYN Scan)"

  echo -e "Inserisci l'IP del target da scansionare (es: ${LOCAL_IP%.*}.1):"
  read -r TARGET

  if [[ -z "$TARGET" ]]; then
    TARGET="${LOCAL_IP%.*}.1"
    warning "Nessun IP inserito. Uso il gateway: $TARGET"
  fi

  echo -e "\n${BOLD}Obiettivo:${NC} identificare le porte aperte su $TARGET"

  echo -e "\n${BOLD}━ Parte A: scansione porte comuni (top 1000)${NC}"
  echo -e "Comando: nmap -sS $TARGET\n"

  echo -e "Come funziona il SYN scan:"
  echo -e "  Client  ──── SYN ────►  Target"
  echo -e "  Client  ◄── SYN/ACK ──  Target   (porta APERTA)"
  echo -e "  Client  ──── RST ────►  Target   (non completa l'handshake)"
  echo -e ""
  echo -e "  Client  ──── SYN ────►  Target"
  echo -e "  Client  ◄──── RST ────  Target   (porta CHIUSA)"
  echo -e ""
  echo -e "  Client  ──── SYN ────►  Target   (nessuna risposta = FILTERED)\n"

  press_enter

  info "Esecuzione: nmap -sS $TARGET"
  echo -e "${BLUE}────────────────────────────────────────${NC}"

  if [[ "$IS_ROOT" == true ]]; then
    nmap -sS "$TARGET"
  else
    warning "SYN scan richiede root. Uso TCP Connect scan (-sT) come alternativa..."
    nmap -sT "$TARGET"
  fi

  echo -e "${BLUE}────────────────────────────────────────${NC}"

  echo -e "\n${BOLD}━ Parte B: scansione TUTTE le porte (65535)${NC}"
  echo -e "Comando: nmap -sS -p- $TARGET"
  warning "Questa scansione è più lenta (può richiedere 2-5 minuti)."
  echo -e "\nEseguire la scansione completa? [s/N]"
  read -r risposta

  if [[ "$risposta" =~ ^[Ss]$ ]]; then
    info "Esecuzione: nmap -sS -p- $TARGET (attendere...)"
    echo -e "${BLUE}────────────────────────────────────────${NC}"
    if [[ "$IS_ROOT" == true ]]; then
      nmap -sS -p- "$TARGET"
    else
      nmap -sT -p- "$TARGET"
    fi
    echo -e "${BLUE}────────────────────────────────────────${NC}"
  else
    info "Scansione completa saltata."
  fi

  press_enter
}

# ── ESERCIZIO 3: VERSION + OS DETECTION ──────────────────────────────────────
esercizio_3() {
  step "Esercizio 3 — Version Detection e OS Fingerprinting"

  echo -e "Inserisci l'IP del target (stesso di prima o nuovo):"
  read -r TARGET

  if [[ -z "$TARGET" ]]; then
    TARGET="${LOCAL_IP%.*}.1"
    warning "Nessun IP inserito. Uso: $TARGET"
  fi

  echo -e "\n${BOLD}Obiettivo:${NC} identificare versioni dei servizi e sistema operativo"
  echo -e "\n${BOLD}Flag usati:${NC}"
  echo -e "  ${CYAN}-sV${NC}  → version detection: interroga ogni servizio aperto"
  echo -e "  ${CYAN}-O${NC}   → OS detection: analizza le risposte TCP/IP per identificare l'OS"
  echo -e "  ${CYAN}-T4${NC}  → timing aggressivo (più veloce su reti locali)\n"

  press_enter

  info "Esecuzione: nmap -sV -O -T4 $TARGET"
  echo -e "${BLUE}────────────────────────────────────────${NC}"

  if [[ "$IS_ROOT" == true ]]; then
    nmap -sV -O -T4 "$TARGET"
  else
    warning "OS detection richiede root. Eseguo solo version detection..."
    nmap -sV -T4 "$TARGET"
  fi

  echo -e "${BLUE}────────────────────────────────────────${NC}"

  echo -e "\n${BOLD}━ Salvataggio output in XML${NC}"
  echo -e "Comando: nmap -sV -oX scan_result.xml $TARGET\n"

  echo -e "Salvare l'output in XML per analisi con Python? [s/N]"
  read -r risposta

  if [[ "$risposta" =~ ^[Ss]$ ]]; then
    OUTPUT_FILE="scan_$(echo $TARGET | tr '.' '_').xml"
    nmap -sV -oX "$OUTPUT_FILE" "$TARGET"
    success "Output salvato in: $OUTPUT_FILE"
    info "Puoi analizzarlo con: python3 nmap_scanner.py $TARGET"
  fi

  press_enter
}

# ── SFIDE BONUS ───────────────────────────────────────────────────────────────
sfide_bonus() {
  step "Sfide Bonus"

  echo -e "${BOLD}Completa queste sfide per consolidare l'apprendimento:${NC}\n"

  echo -e "  ${CYAN}□ Sfida 1:${NC} Usa ${BOLD}-A${NC} (aggressive scan) e confronta con ${BOLD}-sV -O${NC} separati."
  echo -e "             Comando: sudo nmap -A $TARGET"
  echo -e "             Domanda: quali informazioni aggiuntive ottieni?\n"

  echo -e "  ${CYAN}□ Sfida 2:${NC} Esegui la stessa scansione con e senza ${BOLD}sudo${NC}."
  echo -e "             Domanda: perché i risultati sono diversi?\n"

  echo -e "  ${CYAN}□ Sfida 3:${NC} Prova i diversi template di timing."
  echo -e "             Comandi: nmap -T1 $TARGET  vs  nmap -T4 $TARGET"
  echo -e "             Domanda: quanto cambia il tempo di scansione?\n"

  echo -e "  ${CYAN}□ Sfida 4:${NC} Analizza l'output XML con Python."
  echo -e "             Comando: python3 nmap_scanner.py $TARGET\n"

  echo -e "  ${CYAN}□ Sfida 5:${NC} Scansiona solo porte UDP (più lento)."
  echo -e "             Comando: sudo nmap -sU --top-ports 20 $TARGET\n"

  echo -e "${YELLOW}Soluzioni commentate:${NC} ./solutions/walkthrough.md"
  echo -e "${YELLOW}Video walkthrough:${NC}    youtube.com/@profgiagnotti"
  echo -e "${YELLOW}Articolo completo:${NC}    profgiagnotti.it/blog/cybersecurity/nmap-guida-completa"
}

# ── RIEPILOGO FINALE ──────────────────────────────────────────────────────────
riepilogo() {
  step "Riepilogo Comandi del Lab"

  echo -e "${BOLD}Comandi eseguiti oggi:${NC}\n"
  echo -e "  ${GREEN}nmap -sn $SUBNET${NC}"
  echo -e "  → Host discovery sulla rete locale\n"
  echo -e "  ${GREEN}nmap -sS $TARGET${NC}"
  echo -e "  → SYN scan sulle 1000 porte più comuni\n"
  echo -e "  ${GREEN}nmap -sS -p- $TARGET${NC}"
  echo -e "  → SYN scan su tutte le 65535 porte\n"
  echo -e "  ${GREEN}nmap -sV -O -T4 $TARGET${NC}"
  echo -e "  → Version detection + OS fingerprinting\n"
  echo -e "  ${GREEN}nmap -sV -oX output.xml $TARGET${NC}"
  echo -e "  → Salvataggio output in XML\n"

  echo -e "${BLUE}────────────────────────────────────────${NC}"
  echo -e "\n${BOLD}Prossimo Lab:${NC} Lab #02 — Wireshark: analisi del traffico di rete"
  echo -e "             github.com/profgiagnotti/cyber-labs\n"

  success "Lab #01 completato! Buono studio."
  echo -e "\n${CYAN}Prof. Giagnotti · profgiagnotti.it${NC}\n"
}

# ── MENU PRINCIPALE ───────────────────────────────────────────────────────────
main() {
  clear
  banner
  check_root
  check_nmap
  detect_network

  while true; do
    step "Menu Esercizi"
    echo -e "  ${BOLD}1.${NC} Esercizio 1 — Host Discovery"
    echo -e "  ${BOLD}2.${NC} Esercizio 2 — Scansione Porte (SYN Scan)"
    echo -e "  ${BOLD}3.${NC} Esercizio 3 — Version Detection e OS Fingerprinting"
    echo -e "  ${BOLD}4.${NC} Sfide Bonus"
    echo -e "  ${BOLD}5.${NC} Riepilogo comandi"
    echo -e "  ${BOLD}0.${NC} Esci\n"

    prompt "Scegli un esercizio [0-5]:"
    read -r scelta

    case $scelta in
      1) esercizio_1 ;;
      2) esercizio_2 ;;
      3) esercizio_3 ;;
      4) sfide_bonus ;;
      5) riepilogo   ;;
      0)
        echo -e "\n${CYAN}Arrivederci! · profgiagnotti.it${NC}\n"
        exit 0
        ;;
      *)
        warning "Scelta non valida. Inserisci un numero da 0 a 5."
        ;;
    esac
  done
}

# ── AVVIO ─────────────────────────────────────────────────────────────────────
main
