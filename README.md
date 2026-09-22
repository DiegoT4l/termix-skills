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

```bash
git clone https://github.com/DiegoT4l/termix-skills.git
cd termix-skills && ./install.sh
```

`install.sh` symlinks the skills into every known skill directory that already
exists on the machine (Claude Code, Copilot, and others). Symlinks mean a
`git pull` updates every agent at once.

```
./install.sh --dir PATH    install into a runtime the script does not know
./install.sh --copy        copy instead of symlinking
./install.sh --list        preview, change nothing
./install.sh --uninstall   undo
```

**Agents without a skill system** (opencode, Codex, and others): point them at
[`AGENTS.md`](AGENTS.md). The skills are plain Markdown and can be read directly,
with no runtime dependency.

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

## For AI agents

[`AGENTS.md`](AGENTS.md) is the agent-facing entry point: install paths, which
file to load for which task, and the safety rules that apply regardless of
runtime — chiefly that `hosts export` emits decrypted credentials and that
passwords must never be passed in `argv`.

## Licence

Apache-2.0. See `LICENSE`.
