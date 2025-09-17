# Lab: OSPF Multi-Area Design

Hands-on lab to build, validate, and harden a multi-area OSPF deployment. Follow the steps below, capture evidence, and save all artifacts inside this folder.

---

## 1. Objectives
- Stand up a four-router topology with a backbone (Area 0) and two non-backbone areas (Areas 10 and 20).
- Validate neighbor adjacency, LSDB synchronization, and SPF routing outcomes.
- Implement basic hardening (passive interfaces and authentication) and confirm continued reachability.
- Document findings, validation output, and improvement ideas for hiring conversations.

## 2. Topology at a Glance
```
   Area 10            Area 0 (Backbone)            Area 20
R1 -------- R2 ================== R3 -------- R4
Loopbacks 10.1.x     Transit 10.0.x               Loopbacks 10.2.x
```
| Device | Role | Interfaces | Area Membership |
| --- | --- | --- | --- |
| R1 | Internal router | g0/0 to R2, lo0 10.1.1.1/32 | Area 10 |
| R2 | ABR (Area 10 to Area 0) | g0/0 to R1, g0/1 to R3, lo0 10.0.0.2/32 | Areas 10 and 0 |
| R3 | ABR (Area 0 to Area 20) | g0/0 to R2, g0/1 to R4, lo0 10.0.0.3/32 | Areas 0 and 20 |
| R4 | Internal router | g0/0 to R3, lo0 10.2.2.2/32 | Area 20 |

> Tip: add more loopbacks or stub networks if you want extra routes for testing.

---

## 3. Prerequisites
- Emulator: EVE-NG, GNS3, or Cisco Packet Tracer (IOSv or IOL images work well in EVE-NG).
- Base IOS knowledge: interface addressing, OSPF configuration, authentication.
- Tools installed: Wireshark for packet captures, ping and traceroute, and a text editor for configs.

Create subfolders before you start collecting artifacts:
```
mkdir captures configs validation
```
- `captures/`: Packet captures (`.pcap`) showing OSPF adjacency and LSAs.
- `configs/`: Final device configs (`r1.cfg`, `r2.cfg`, etc.).
- `validation/`: Command outputs (for example `show ip ospf neighbor`, `show ip route`) saved as `.txt`.

---

## 4. Build the Topology
1. Place four routers and connect interfaces to match the diagram.
2. Assign the following IP addresses (adjust if your environment needs a different plan):
   - R1 g0/0 -> 10.0.10.1/30
   - R2 g0/0 -> 10.0.10.2/30
   - R2 g0/1 -> 10.0.0.1/30
   - R3 g0/0 -> 10.0.0.2/30
   - R3 g0/1 -> 10.0.20.1/30
   - R4 g0/0 -> 10.0.20.2/30
3. Add loopbacks:
   - R1 lo0 10.1.1.1/32, lo1 10.1.2.1/32
   - R2 lo0 10.0.0.2/32
   - R3 lo0 10.0.0.3/32
   - R4 lo0 10.2.2.2/32, lo1 10.2.3.2/32
4. Save configs as you go (`write memory`).

---

## 5. Configure OSPF
Use the snippets below as a starting point. Adjust interface names to match your emulator.

### R1 (Area 10 internal)
```bash
conf t
hostname R1
interface g0/0
 ip address 10.0.10.1 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface lo0
 ip address 10.1.1.1 255.255.255.255
 ip ospf network point-to-point
 ip ospf 10 area 10
!
interface lo1
 ip address 10.1.2.1 255.255.255.255
 ip ospf 10 area 10
!
router ospf 10
 router-id 1.1.1.1
 network 10.0.10.0 0.0.0.3 area 10
 network 10.1.1.1 0.0.0.0 area 10
 network 10.1.2.1 0.0.0.0 area 10
 passive-interface lo0
 passive-interface lo1
!
end
```

### R2 (ABR 10 and 0)
```bash
conf t
hostname R2
interface g0/0
 ip address 10.0.10.2 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface g0/1
 ip address 10.0.0.1 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface lo0
 ip address 10.0.0.2 255.255.255.255
 ip ospf 10 area 0
!
router ospf 10
 router-id 2.2.2.2
 network 10.0.10.0 0.0.0.3 area 10
 network 10.0.0.0 0.0.0.3 area 0
 network 10.0.0.2 0.0.0.0 area 0
 area 10 authentication message-digest
!
end
```

### R3 (ABR 0 and 20)
```bash
conf t
hostname R3
interface g0/0
 ip address 10.0.0.2 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface g0/1
 ip address 10.0.20.1 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface lo0
 ip address 10.0.0.3 255.255.255.255
 ip ospf 10 area 0
!
router ospf 10
 router-id 3.3.3.3
 network 10.0.0.0 0.0.0.3 area 0
 network 10.0.20.0 0.0.0.3 area 20
 network 10.0.0.3 0.0.0.0 area 0
 area 20 stub no-summary
!
end
```

### R4 (Area 20 internal)
```bash
conf t
hostname R4
interface g0/0
 ip address 10.0.20.2 255.255.255.252
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 C1sc0!
!
interface lo0
 ip address 10.2.2.2 255.255.255.255
 ip ospf 10 area 20
!
interface lo1
 ip address 10.2.3.2 255.255.255.255
 ip ospf 10 area 20
!
router ospf 10
 router-id 4.4.4.4
 network 10.0.20.0 0.0.0.3 area 20
 network 10.2.2.2 0.0.0.0 area 20
 network 10.2.3.2 0.0.0.0 area 20
 passive-interface lo0
 passive-interface lo1
!
end
```

> Use the same MD5 key on both ends of each link or the neighbors will not form.

---

## 6. Validate and Collect Evidence
Run these commands on all routers and save outputs into `validation/`:
- `show ip ospf neighbor`
- `show ip ospf interface brief`
- `show ip route ospf`
- `show ip ospf database router`
- `ping 10.2.2.2 source 10.1.1.1`

Use Wireshark with filter `ospf` to capture the adjacency bring-up between R1 and R2 plus at least one LSA refresh. Export the packet capture to `captures/ospf-area10.pcap`.

Document key validation results in this README under **Results**:
- Neighbor table summary
- Route reachability matrix
- LSDB highlights (for example stub area summaries)

---

## 7. Hardening and Enhancements
- Enable `ip ospf authentication message-digest` on all OSPF interfaces.
- Configure `passive-interface default` and re-enable on transit links to reduce LSA noise.
- Optional: tune OSPF timers or implement route filtering (for example `area 20 range 10.2.0.0 255.255.0.0`) and document the effect.

Capture before and after outputs in `validation/` to show the change did not break routing.

---

## 8. Cleanup and Reflection
1. Export final configs (`show run`) into `configs/`.
2. Create `reflection.md` with:
   - What went well
   - Issues debugged (including commands you used)
   - Next iteration ideas (for example add redistribution or simulate failure)
3. Update `../../journal.md` with a quick summary.

---

## 9. Deliverables Checklist
- [ ] `configs/r1.cfg` through `configs/r4.cfg`
- [ ] `captures/ospf-area10.pcap`
- [ ] `validation/show-ip-ospf-neighbor.txt`
- [ ] `validation/show-ip-route.txt`
- [ ] Updated README results section
- [ ] `reflection.md`
- [ ] `journal.md` entry created or updated

---

## 10. Interview Talking Points
- Explain why multi-area OSPF improves scalability by reducing LSDB size and LSA flooding.
- Discuss how authentication and passive interfaces protect the control plane.
- Highlight the validation steps you followed and how you would monitor the design in production.

Capture snippets of these talking points in `reflection.md` so you can review them before interviews.