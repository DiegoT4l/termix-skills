# termix-skills

LLM-first Claude Code skills for operating [Termix](https://github.com/LukeGus/Termix),
a self-hosted SSH and remote-desktop manager, as the primary way an agent reaches
managed hosts.

Verified against **Termix 2.7.1** and **`@termix-cli/cli` 1.0.1**.

## Skills

| Skill | Use it for |
|---|---|
| `termix-ssh` | Running commands, shells and file transfers on managed hosts |
| `termix-provisioning` | Registering hosts and credentials, and diagnosing SSH auth failures |
| `termix-fleet-ops` | Fleets, snippets, tunnels and Docker across many hosts |

Each skill keeps its body short and pushes detail into `references/`:

- `termix-ssh/references/cli-reference.md` — the full command and option surface
- `termix-ssh/references/api-reference.md` — REST routes and the `ssh_data` model
- `termix-provisioning/references/auth-troubleshooting.md` — the auth decision tree
- `termix-fleet-ops/references/fleets-snippets.md` — multi-host operations

## Install

The repo is the source of truth; skills enter Claude Code by symlink.

```bash
git clone git@github.com:DiegoT4l/termix-skills.git ~/Projects/termix-skills
for s in termix-ssh termix-provisioning termix-fleet-ops; do
  ln -s ~/Projects/termix-skills/skills/$s ~/.claude/skills/$s
done
```

Skill discovery resolves symlinks.

## Why these exist

Termix's CLI help is occasionally wrong and its failure messages are uniform.
These skills encode what the documentation does not:

- `hosts create --credential-id` returns **HTTP 500** unless `--auth-type key` is
  also passed, contradicting its own help text.
- Every SSH key failure reports the same `All configured authentication methods
  failed`, so the skills lead with a fingerprint comparison instead of guesswork.
- `StrictModes` makes sshd ignore `authorized_keys` **without logging anything**
  when directory ownership is wrong — the usual cause being a container id-shift.
- `hosts export` emits **decrypted credentials**.
- The CLI has no Proxmox support; discovery and import are web-UI only, and the
  import fails for every guest unless the key was distributed first.

## Licence

Apache-2.0. See `LICENSE`.
