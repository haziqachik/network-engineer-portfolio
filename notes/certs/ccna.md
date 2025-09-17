# CCNA Study Notes

## Certification Goal
- Target exam: Cisco CCNA 200-301
- Focus period: 8–12 weeks (adjust as needed)
- Daily commitment: 60–90 minutes of theory + lab practice

## Skill Areas
1. Networking fundamentals (IPv4/IPv6, subnetting, VLANs)
2. Network access (switching, EtherChannel)
3. IP connectivity (static routes, OSPFv2, inter-VLAN routing)
4. IP services (NAT, DHCP, FHRP basics)
5. Security fundamentals (ACLs, device hardening)
6. Automation & programmability (API basics, Cisco DNA Center overview)

## Weekly Plan Snapshot
| Week | Theme | Key Actions | Deliverables |
| --- | --- | --- | --- |
| 1 | IP fundamentals refresh | Subnet drills, review TCP/UDP, build VLAN lab | Subnet worksheet, VLAN config notes |
| 2 | Routing basics | Static routes, default routes, packet-forwarding logic | Lab write-up: static routing topology |
| 3 | OSPF introduction | Study OSPF theory, configure single-area lab | Add OSPF notes + lab outputs |
| 4 | Network services | DHCP/NAT lab, Syslog/SNMP overview | DHCP/NAT configs + validation |
| 5 | Security | ACL lab, device hardening checklist | ACL config examples |
| 6 | Automation & review | REST/JSON overview, Cisco DevNet sandboxes | Quick script snippet, practice exam |

Update this table as you progress or adjust the timeline.

## Topic Deep Dives
### OSPF (Open Shortest Path First)
- Link-state routing protocol: every router builds a map of the network and calculates shortest paths with Dijkstra (SPF) algorithm.
- Organizes networks into *areas* to reduce database size. Area 0 (backbone) connects to other areas.
- Neighbors form adjacencies by exchanging Hello packets; LSAs advertise network information.
- CCNA scope: single-area OSPF configuration, router IDs, passive interfaces, cost manipulation, verifying neighbors/routes (`show ip ospf neighbor`, `show ip route`).
- Lab idea: extend `labs/ospf-multi-area` by first building a single-area version and comparing outputs.

### Switching & VLANs
- VLANs isolate broadcast domains on switches.
- Configure access/trunk ports, understand 802.1Q tagging, native VLAN.
- Practice `show vlan`, `show interfaces trunk` to verify.

### IPv4/IPv6 Subnetting
- Master CIDR notation, prefix length ? subnet mask conversion.
- Practice VLSM for different host requirements.
- IPv6: understand global unicast, link-local, SLAAC vs DHCPv6.

(Continue adding sections for security, services, automation.)

## Practice Resources
- Cisco Press Official Cert Guide (Vol 1 & 2)
- Cisco Modeling Labs, Packet Tracer, or GNS3 for hands-on
- Boson ExSim or CBT practice exams
- Cisco Learning Network study groups

## Progress Log
| Date | Topic Covered | Lab/Practice Completed | Notes |
| --- | --- | --- | --- |
| 2025-09-18 | Kickoff | Created CCNA study plan | |

Keep this log updated after each study session.