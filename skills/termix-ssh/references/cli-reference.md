# Termix CLI reference

Verified against `@termix-cli/cli` 1.0.1 talking to Termix 2.7.1.

## Install and authenticate

```bash
bun add -g @termix-cli/cli          # or npm i -g
termix login --url https://termix.example.com
termix login --url URL --username U --password-stdin --totp 123456   # scripted
termix whoami                        # user + session expiry
termix logout
```

Config lives in `~/.config/termix/config.json` (url + username only; the session
token is not stored there in plain form).

For unattended use set `TERMIX_URL` and `TERMIX_API_KEY` instead of logging in.

## Global options

`--url` · `--api-key` · `--json` / `--no-json` · `-q` (ids only) · `--no-color` ·
`--insecure` (skip TLS verification) · `-V`

Output is a table on a TTY and JSON when piped. `-q` prints one id per line, which
is what you want for scripting loops.

## Commands

| Group | Subcommands |
|---|---|
| `hosts` | `list` `get` `create` `update` `delete` `export` `import` `enroll` |
| `credentials` | `list` `get` `create` `update` `delete` |
| `exec` | `exec <hostId> <command...>` |
| `ssh` | `ssh <hostId>` |
| `files` | `ls` `cat` `get` `put` `mkdir` `rm` |
| `tunnel` | `list` `show` `start` `stop` |
| `docker` | `ps` `logs` `start` `stop` `restart` `pause` `unpause` |
| `fleets` | `list` `members` `create` `delete` `add-host` `remove-host` `exec` |
| `snippets` | `list` `create` `update` `delete` `run` |
| `sessions` | `list` `revoke` `revoke-all` |
| `users` | `list` (admin only) |
| `api-keys` | `list` `create` `revoke` |
| `alerts` | `list` `dismiss` `undismiss` |
| `audit-logs` | — |

## hosts create / update / enroll

```
--name --ip --port --username
--auth-type password|key
--key-file <path> | --password <p> | --credential-id <id>
--key-password <passphrase>
--folder --tags
--enable-terminal --enable-file-manager --enable-docker --enable-tunnel
```

`--ip` and `--username` are required, plus one of `--password`, `--key-file` or
`--credential-id`. **With `--credential-id` you must also pass `--auth-type key`**
or the API returns HTTP 500.

`hosts update` changes only the fields you pass. `hosts enroll` registers a host
for automated provisioning and requires an API key.

## hosts list / export / import

```
hosts list   --folder <f> --tag <t>
hosts export --output <path> --share
hosts import <file> --overwrite
```

`export` contains **decrypted credentials**. `--share` strips personal fields.
`import` accepts up to 100 hosts per call.

## credentials create / update

```
--name --description --folder --tags
--auth-type password|key --username
--key-file <path> | --password <p>
--key-password <passphrase>
```

`credentials get <id>` returns metadata plus the **derived public key**,
`detectedKeyType`, `hasKey`, `hasKeyPassword`, `usageCount`. Private material is
never printed. Prefer `TERMIX_CREDENTIAL_PASSWORD` /
`TERMIX_CREDENTIAL_KEY_PASSWORD` over flags.

## exec / ssh / files

```
termix exec <hostId> <command...>        # remote exit code; 255 = CLI/API error
termix ssh  <hostId> --command <c> --path <dir> --tmux <session>
termix files ls|cat|mkdir  <hostId>:/path
termix files get <hostId>:/path [local]
termix files put <local> <hostId>:/path
termix files rm  <hostId>:/path [-r]
```

`ssh` opens a WebSocket and therefore needs a **session token**; API keys cannot
open it. `exec`, `files` and `docker` work with an API key.

## snippets / fleets / api-keys

```
snippets create --name --content | --content-file --description --folder
snippets run <id> --host <hostId> --input NAME=VALUE   # repeatable
fleets create --name --description
fleets exec <fleetId> <command...>       # non-zero if ANY host failed
api-keys create --name --user <userId> --expires-at <ISO date>
```

An API key token is displayed **once** and cannot be retrieved again.

## Known defects (2.7.1 / CLI 1.0.1)

- `hosts create --credential-id` without `--auth-type key` → HTTP 500,
  `NOT NULL constraint failed: ssh_data.auth_type`. The help text is wrong.
- `--auth-type credential` is rejected, although `hosts get` reports exactly that
  value for hosts created through the web UI.
- `usageCount` on a credential does not increment for CLI `exec`. Do not use it
  to decide whether a credential works.
- The CLI has **no Proxmox support**. Proxmox discovery and import exist only in
  the web UI.
