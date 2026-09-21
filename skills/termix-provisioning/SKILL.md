---
name: termix-provisioning
description: "Trigger: registrar host en termix, dar de alta servidor, add host, authentication methods failed, credencial ssh, importar hosts. Register Termix hosts and diagnose SSH auth failures."
license: Apache-2.0
metadata:
  author: "DiegoT4l"
  version: "1.0"
---

# Registering Termix hosts and fixing auth

## Activation Contract

Load when adding hosts or credentials to Termix, bulk-importing, or when a host
fails with `All configured authentication methods failed`.

## Hard Rules

- ALWAYS pass `--auth-type key` together with `--credential-id`. Omitting it
  returns **HTTP 500** (`NOT NULL constraint failed: ssh_data.auth_type`) even
  though the help says the credential is enough. `--auth-type credential` is
  rejected despite being what `hosts get` reports.
- Create ONE shared credential and reference it by id; never paste a key per host.
- Authorizing a key on a hypervisor does NOT authorize it on its guests. Each
  guest has its own `authorized_keys`.
- Adding a public key to a host grants access. Confirm with the user first, and
  label the key with a comment so it is revocable.
- NEVER print a private key. `credentials get` exposes only the derived public key.

## Decision Gates

| Symptom | Check |
|---------|-------|
| Auth fails on every host | Key not authorized — compare fingerprints (step 2) |
| Auth fails on ONE host | Ownership / `StrictModes` — see references |
| HTTP 500 on create | Missing `--auth-type key` |
| Key parsed but rejected | RSA signed as legacy `ssh-rsa`; use ed25519 |
| Reached `Authenticating as` in logs | Network and bans are ruled out |

## Execution Steps

1. Create the credential once:
   `termix credentials create --name N --auth-type key --username root --key-file K`
2. Diagnose auth by fingerprint, not by guessing:
   `termix credentials get <id>` → take `publicKey` → `ssh-keygen -lf` → compare
   against the target's `authorized_keys` fingerprints.
3. Distribute the key to guests with `assets/distribute-key.sh` (idempotent).
4. Create hosts with `--auth-type key --credential-id <id> --folder F --tags T`.
5. Verify every host: `termix exec <id> hostname`. A host that is not verified
   is not registered.

## Output Contract

Return a table of host id, name, address, folder, and verified yes/no. Name any
host that failed and the specific cause.

## References

- `references/auth-troubleshooting.md` — full decision tree, including the
  `StrictModes` ownership trap.
- `assets/distribute-key.sh` — push a public key to LXC/VM guests.
