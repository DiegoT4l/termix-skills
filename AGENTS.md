# AGENTS.md

Entry point for any AI agent working with [Termix](https://github.com/LukeGus/Termix),
a self-hosted SSH manager. Read this file first; it works whether or not your
runtime has a skill system.

Verified against **Termix 2.7.1** and **`@termix-cli/cli` 1.0.1**.

## Install

**If your runtime loads skill directories** (Claude Code, Copilot, and others):

```bash
git clone https://github.com/DiegoT4l/termix-skills.git
cd termix-skills && ./install.sh
```

`install.sh` symlinks the three skills into every known skill directory that
already exists on the machine. Use `--dir PATH` for a runtime it does not know,
`--copy` if symlinks are unavailable, `--list` to preview, `--uninstall` to undo.
Symlinks mean `git pull` updates every agent at once.

**If your runtime has no skill system** (opencode, Codex, and others): read the
three `skills/*/SKILL.md` files directly. They are plain Markdown with no runtime
dependency. Load the one matching the task, then follow its `References` into
`references/` when you need detail.

## Which file to load

| Task | Load |
|---|---|
| Run a command, open a shell, move a file on a managed host | `skills/termix-ssh/SKILL.md` |
| Add hosts or credentials, or SSH auth is failing | `skills/termix-provisioning/SKILL.md` |
| Act on many hosts, or use snippets, tunnels, Docker | `skills/termix-fleet-ops/SKILL.md` |
| Need the full command surface | `skills/termix-ssh/references/cli-reference.md` |
| Need REST routes or the data model | `skills/termix-ssh/references/api-reference.md` |

## Rules that apply to every agent

These hold regardless of which skill you loaded. Violating them leaks credentials
or destroys access.

1. **`termix hosts export` emits decrypted credentials.** Never write it to a
   repository, a note, a log, or a chat message. `--share` strips personal fields
   and is the only form safe to hand to another person.
2. **Never pass `--password` or `--key-password` as arguments.** `argv` is visible
   to every process on the host. Use `TERMIX_HOST_PASSWORD`,
   `TERMIX_HOST_KEY_PASSWORD`, `TERMIX_CREDENTIAL_PASSWORD`,
   `TERMIX_CREDENTIAL_KEY_PASSWORD`.
3. **Never print a private key.** `credentials get` returns only the derived
   public key; that is what you compare fingerprints against.
4. **Adding a public key to a host grants shell access.** Confirm with the human
   first, and give the key a comment so it stays revocable.
5. **Resolve host ids from `termix hosts list`.** Never guess an id: the wrong id
   runs your command on the wrong machine.
6. **A non-zero exit is the remote exit code.** `255` means a CLI or API error,
   not a remote failure. Report which one it was.
7. **Verify before reporting success.** A host that has not answered
   `termix exec <id> hostname` is not registered, whatever the API returned.

## Authenticate

```bash
termix login --url https://termix.example.com          # interactive
termix login --url URL --username U --password-stdin   # scripted
export TERMIX_URL=... TERMIX_API_KEY=tmx_...           # unattended
termix whoami
```

API keys cannot open a WebSocket, so `termix ssh` requires a session token from
`termix login`. `exec`, `files` and `docker` work with either.

## Known defects this repo encodes

The upstream help text is wrong in places and every auth failure reports the same
message. These are the traps the skills exist to prevent:

- `hosts create --credential-id` returns **HTTP 500**
  (`NOT NULL constraint failed: ssh_data.auth_type`) unless `--auth-type key` is
  also passed, contradicting its own help. `--auth-type credential` is rejected
  even though `hosts get` reports exactly that value.
- Every key failure is `All configured authentication methods failed`. Start by
  comparing fingerprints, not by guessing among passphrase, format and algorithm.
- `StrictModes` makes sshd ignore `authorized_keys` **with no log entry** when
  directory ownership is wrong.
- A credential's `usageCount` does not increment for CLI `exec`; it is not a
  health signal.
- The CLI has **no Proxmox support**. Discovery and import are web-UI only, and
  the import fails on every guest unless the key was distributed beforehand.
- `tunnel start` takes a host id plus an index; `tunnel stop` takes a full name.

## Layout

```
skills/termix-ssh/           SKILL.md + references/{cli,api}-reference.md
skills/termix-provisioning/  SKILL.md + references/auth-troubleshooting.md
                             + assets/distribute-key.sh
skills/termix-fleet-ops/     SKILL.md + references/fleets-snippets.md
```

Licence: Apache-2.0.
