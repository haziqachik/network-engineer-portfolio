# Lab: OSPF Single-Area Fundamentals

Quick lab to introduce OSPF in a single-area deployment. This builds confidence with CCNA-level tasks before you expand to multi-area designs.

---

## 1. Objectives
- Form OSPF adjacencies between three routers in Area 0.
- Advertise loopback networks and verify reachability across the topology.
- Practice verification commands: `show ip ospf neighbor`, `show ip route`, `show ip protocols`.
- Capture evidence, configs, and a short reflection for interviews.

---

## 2. Topology
```
R1 ---- R2 ---- R3
 \      |      /
  \     |     /
   \    |    /
   Loopbacks on each router
```
| Device | Interfaces | Networks |
| --- | --- | --- |
| R1 | g0/0 to R2 (10.0.12.1/30), lo0 10.1.1.1/32 | Area 0 |
| R2 | g0/0 to R1 (10.0.12.2/30), g0/1 to R3 (10.0.23.2/30), lo0 10.2.2.2/32 | Area 0 |
| R3 | g0/0 to R2 (10.0.23.3/30), lo0 10.3.3.3/32 | Area 0 |

> Use Packet Tracer, EVE-NG, or even three CSR/IOSv devices in CML.

---

## 3. Configuration Steps
1. Assign IP addresses to interfaces per the topology.
2. Enable OSPF process 1 and advertise connected networks.
3. Set router IDs to loopback addresses for stability.
4. Verify neighbors and routes.

Sample configuration snippets to follow:

### R1
```bash
conf t
hostname R1
interface g0/0
 ip address 10.0.12.1 255.255.255.252
 no shutdown
!
interface lo0
 ip address 10.1.1.1 255.255.255.255
!
router ospf 1
 router-id 1.1.1.1
 network 10.0.12.0 0.0.0.3 area 0
 network 10.1.1.1 0.0.0.0 area 0
!
end
```

### R2
```bash
conf t
hostname R2
interface g0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
!
interface g0/1
 ip address 10.0.23.2 255.255.255.252
 no shutdown
!
interface lo0
 ip address 10.2.2.2 255.255.255.255
!
router ospf 1
 router-id 2.2.2.2
 network 10.0.12.0 0.0.0.3 area 0
 network 10.0.23.0 0.0.0.3 area 0
 network 10.2.2.2 0.0.0.0 area 0
!
end
```

### R3
```bash
conf t
hostname R3
interface g0/0
 ip address 10.0.23.3 255.255.255.252
 no shutdown
!
interface lo0
 ip address 10.3.3.3 255.255.255.255
!
router ospf 1
 router-id 3.3.3.3
 network 10.0.23.0 0.0.0.3 area 0
 network 10.3.3.3 0.0.0.0 area 0
!
end
```

Optional enhancements once basic OSPF works:
- Set interface bandwidth to influence cost (`ip ospf cost <value>`).
- Configure passive interfaces on loopbacks (`passive-interface lo0`).
- Add a fourth router or more loopbacks.

---

## 4. Validation Checklist
Run these commands on each router and save outputs to `validation/`:
- `show ip ospf neighbor`
- `show ip route ospf`
- `show ip ospf interface brief`
- `ping 10.3.3.3 source 10.1.1.1` (and other cross-router tests)

Also capture a Wireshark trace (filter `ospf`) of the adjacency forming between R1 and R2, save to `captures/`.

Document summary results in this README:
- Neighbor table (state should be FULL with two neighbors on R2).
- Routes learned on each router.

---

## 5. Reflection
Use `reflection.md` to note:
- What commands helped verify OSPF quickly.
- Any issues you hit (mis-typed network statements, router IDs, etc.).
- How you’d explain OSPF to a non-technical stakeholder.

Update `../../journal.md` with the date and what you accomplished.

---

## 6. Interview Talking Points
- Explain how OSPF elects DR/BDR on broadcast networks (mention no election occurs on point-to-point links).
- Discuss differences between link-state (OSPF) and distance-vector (RIP) protocols.
- Highlight troubleshooting steps you used (checking neighbors, verifying LSAs, pings with source IPs).

Keep your deliverables checklist handy:
- [ ] Config backups for R1–R3 in `configs/`
- [ ] Validation outputs in `validation/`
- [ ] Packet capture in `captures/`
- [ ] Completed `reflection.md`
- [ ] Journal update