---
name: termix-ssh
description: "Trigger: termix, conectar por ssh, entrar al servidor, run a command on a host, remote shell, sftp, transferir archivos. Operate managed SSH hosts through the Termix CLI instead of raw ssh."
license: Apache-2.0
metadata:
  author: "DiegoT4l"
  version: "1.0"
---

# Termix as the SSH manager

## Activation Contract

Load when the task needs a shell, a command, or a file transfer on a host that
Termix manages, or when the user names Termix. Prefer Termix over raw `ssh` so
every access is centrally credentialed and audited.

## Hard Rules

- NEVER run `termix hosts export` into a repo, a vault, or a chat. It emits
  **decrypted credentials**. Use `--share` only when the target is another person.
- NEVER pass `--password` or `--key-password` on the command line. Use
  `TERMIX_HOST_PASSWORD` / `TERMIX_HOST_KEY_PASSWORD`; argv is world-readable.
- API keys CANNOT open a WebSocket: `termix ssh` needs a session token from
  `termix login`. `exec`, `files` and `docker` work with either.
- Resolve a host by id from `termix hosts list`. Do not guess ids.
- Treat a non-zero exit as the remote exit code; `255` means a CLI or API error.

## Decision Gates

| Need | Command |
|------|---------|
| One command, capture output | `termix exec <hostId> '<cmd>'` |
| Interactive shell or tmux | `termix ssh <hostId> [--tmux <s>]` |
| Read a remote file | `termix files cat <hostId>:/path` |
| Move a file | `termix files get\|put` |
| Same command on many hosts | see `termix-fleet-ops` |
| Host missing or auth fails | see `termix-provisioning` |

## Execution Steps

1. Confirm auth: `termix whoami`. If it fails, `termix login --url <url>`.
2. Find the target: `termix hosts list [--folder F] [--tag T]`.
3. Run the narrowest action from the Decision Gates table.
4. Pipe to get JSON (`--json` is implicit when piped); use `-q` for bare ids.
5. Report the remote exit code when it is non-zero.

## Output Contract

Return the host id acted on, the command run, its exit code, and the relevant
output. Never echo secrets, tokens, or export payloads.

## References

- `references/cli-reference.md` — full command and option surface.
- `references/api-reference.md` — REST routes for what the CLI does not cover.
