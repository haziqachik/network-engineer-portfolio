# Automation

Reusable scripts and playbooks that streamline network and security operations. Organize by tooling:
- `ansible/` - Playbooks and roles for device configuration, compliance checks, backup jobs.
- `python/` - Netmiko or NAPALM scripts for inventory, configuration drift, health checks.
- `validation/` - Test harnesses, pytest suites, or Batfish snapshots to prove intent.

Add a `requirements.txt` or `Pipfile` when Python dependencies grow, and document how to run each automation artifact in its own README.