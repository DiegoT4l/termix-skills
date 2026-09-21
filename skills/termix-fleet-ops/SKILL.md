---
name: termix-fleet-ops
description: "Trigger: ejecutar en todos los hosts, fleet, snippet, tunel ssh, docker remoto, run everywhere, bulk command. Run commands across Termix fleets and manage snippets, tunnels and containers."
license: Apache-2.0
metadata:
  author: "DiegoT4l"
  version: "1.0"
---

# Fleet, snippet, tunnel and Docker operations

## Activation Contract

Load when the same action must hit several Termix hosts, when reusing a saved
snippet, or when driving Docker containers or SSH tunnels through Termix.

## Hard Rules

- NEVER run a mutating fleet command before a read-only one has proven the target
  set. Run `termix fleets members <id>` first and show it.
- `fleets exec` exits non-zero if ANY host failed. Inspect per-host output; do not
  report success on a non-zero exit.
- A snippet runs on the host given by `--host`; it has no default. Pass it.
- `docker` and `tunnel` subcommands require that capability enabled on the host
  (`--enable-docker`, `--enable-tunnel`). Enable it with `hosts update`, not by
  recreating the host.
- Stop a tunnel by its full name from `tunnel list`, but start it by its index
  from `tunnel show <hostId>`. They are different identifiers.

## Decision Gates

| Need | Command |
|------|---------|
| Ad-hoc command everywhere | `termix fleets exec <fleetId> '<cmd>'` |
| Reusable parametrised command | `termix snippets run <id> --host <h> --input K=V` |
| Container state | `termix docker ps\|logs\|restart <hostId> <container>` |
| Port forward | `termix tunnel show <hostId>` then `tunnel start <hostId> <idx>` |
| Group hosts once | `fleets create` + `fleets add-host` |

## Execution Steps

1. List fleets and confirm membership before acting.
2. For a sweep, run the read-only form first (`hostname`, `systemctl is-active`).
3. Run the mutating command only after the target set is confirmed.
4. Collect per-host results; treat any failure as a partial run.
5. For repeated operations, save a snippet with `--content-file` rather than
   retyping the command.

## Output Contract

Return a per-host table of name, exit code, and the decisive output line. State
explicitly which hosts failed and which were skipped.

## References

- `references/fleets-snippets.md` — fleet, snippet, tunnel and Docker details.
