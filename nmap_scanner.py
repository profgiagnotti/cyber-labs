#!/usr/bin/env python3
"""
Lab #01 — Nmap Scanner in Python
Prof. Giagnotti — profgiagnotti.it

Questo script esegue una scansione nmap e analizza
l'output XML in modo programmatico.
"""

import nmap
import sys
import json


def scan_target(target: str, ports: str = "1-1000") -> dict:
    """
    Esegue una scansione SYN sul target specificato.
    
    Args:
        target: IP o range CIDR (es: '192.168.1.1' o '192.168.1.0/24')
        ports:  range porte (es: '1-1000' o '80,443,8080')
    
    Returns:
        dizionario con i risultati della scansione
    """
    scanner = nmap.PortScanner()
    
    # -sV: rileva versioni servizi
    # -sS: SYN scan (richiede root)
    # --open: mostra solo porte aperte
    scanner.scan(
        hosts=target,
        ports=ports,
        arguments="-sV --open"
    )
    
    results = {}
    
    for host in scanner.all_hosts():
        results[host] = {
            "stato": scanner[host].state(),
            "porte_aperte": []
        }
        
        for proto in scanner[host].all_protocols():
            for port in scanner[host][proto].keys():
                servizio = scanner[host][proto][port]
                results[host]["porte_aperte"].append({
                    "porta": port,
                    "protocollo": proto,
                    "servizio": servizio["name"],
                    "versione": servizio["version"]
                })
    
    return results


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python nmap_scanner.py  [porte]")
        print("Es:  python nmap_scanner.py 192.168.1.1 80,443")
        sys.exit(1)
    
    target = sys.argv[1]
    ports  = sys.argv[2] if len(sys.argv) > 2 else "1-1000"
    
    print(f"[*] Scansione di {target} sulle porte {ports}...")
    risultati = scan_target(target, ports)
    
    print(json.dumps(risultati, indent=2, ensure_ascii=False))