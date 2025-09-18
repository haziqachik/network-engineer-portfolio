# CEH Bootcamp Lab Notes (SkillsFuture, 5-Day Intensive — 2025)

## Overview
- Provider: SkillsFuture Singapore (authorised EC-Council training partner)
- Format: Instructor-led, five full days (40+ hours) with lab guide and virtual machines
- Goal: Reinforce CEH v12 domains through hands-on labs and reporting exercises

### Environment
- Kali Linux attack box, Windows Server 2019 and Windows 10 victims, Metasploitable 2, OWASP Juice Shop
- Toolset: Nmap, Metasploit Framework, Burp Suite, OWASP ZAP, Nessus Essentials, Hydra, John the Ripper, Wireshark, PowerShell Empire, mimikatz

## Daily Highlights
**Day 1 – Recon & Footprinting**
- Performed passive recon with Maltego, theHarvester, Recon-ng; documented intelligence in markdown report
- Active scans with Nmap (SYN, version detection, NSE scripts) against lab subnet; baseline port/service map saved to `scans/day1-nmap.xml`

**Day 2 – Scanning & Enumeration**
- Enumerated SMB/LDAP using enum4linux and `rpcclient`; captured responder/LLMNR poisoning demo
- Bashed NSE scripts for vulnerability scanning (`smb-vuln-ms17-010`). Stored sample output in `validation/ms17-010.txt`

**Day 3 – Exploitation**
- Launched Metasploit multi/handler with payloads generated via `msfvenom`; exploited MS17-010 and Tomcat manager issues
- Crafted manual buffer overflow (SEH) exercise following course scripts; notes saved in `exploits/buffer-overflow.md`

**Day 4 – Privilege Escalation & Persistence**
- Practiced Windows privilege escalation (service misconfigurations, token impersonation, mimikatz for credential dump)
- Linux escalation using `linpeas`, `sudo -l`, capability abuse; documented successful chains

**Day 5 – Web Attacks & Reporting**
- Cross-site scripting, SQL injection lab on Juice Shop; used Burp Suite Intruder for auth bypass
- Compiled five-page assessment report with remediation steps; template stored as `report/ceh-bootcamp-report.docx`

## Key Takeaways
- Reinforced structured attack lifecycle: recon ? scanning ? gaining access ? maintaining access ? covering tracks
- Practiced ethical reporting: severity rating, business impact articulation, remediation guidance
- Identified tooling gaps for follow-up: deeper PowerShell, malware evasion techniques, purple teaming

## Portfolio Artifacts
- Sanitised screenshots (see `/assets/ceh-bootcamp/` in repo)
- Sample lab write-ups and command transcripts in this folder
- Résumé bullet:
  > *Completed SkillsFuture CEH bootcamp (2025): executed recon-to-persistence labs with Nmap, Metasploit, Burp Suite, mimikatz; produced remediation reports for simulated incidents.*
