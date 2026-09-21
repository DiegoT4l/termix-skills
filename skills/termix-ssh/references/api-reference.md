# Termix REST API notes

Routes observed in Termix 2.7.1. Use them only for what the CLI does not cover;
prefer the CLI everywhere else.

Authenticate with an API key (`Authorization` header, `tmx_...`) for everything
except WebSocket terminals, which require a session token.

## Host and credential routes

| Route | Purpose |
|---|---|
| `/db/host` | Create a host |
| `/db/host/:id` | Read / update / delete |
| `/db/host/:id/export` | Export one host |
| `/db/host/:id/password` | Host password operations |
| `/db/host/:id/wake` | Wake-on-LAN |
| `/db/host/internal`, `/db/host/internal/all` | Internal host records |
| `/db/hosts/export` | Export every host (decrypted) |
| `/bulk-import`, `/bulk-update` | Batch host operations |
| `/ssh-config-import` | Import from an `ssh_config` file body |
| `/database/import` | Whole-database import |
| `/credentials` | Saved credentials |
| `/folders`, `/folders/:name`, `/folders/:name/hosts` | Folder tree |
| `/folders/rename`, `/folders/reorder`, `/folder/share` | Folder management |

## Proxmox integration (web UI only)

| Route | Purpose |
|---|---|
| `/proxmox/discover/stream?hostId=<id>` | Stream guest discovery from a host |

The Proxmox importer discovers guests **over SSH from a host already registered
in Termix**, so that host must authenticate first. Settings exposed in the UI:
default auth type and credential, preferred IP ranges, Docker name patterns,
Windows/RDP name patterns, auto-sync with a minimum 5 minute interval, and
mark-missing behaviour.

The importer assigns the default credential to every guest it creates. If that
key is not present in each guest's own `authorized_keys`, all imported hosts fail
to connect. Distribute the key **before** importing.

## Docker over SSH

`/docker/ssh/connect`, `/connect-totp`, `/connect-warpgate`, `/disconnect`,
`/keepalive`, `/status`.

## Data model

Hosts live in the `ssh_data` table. Fields that matter:

`connectionType` `name` `ip` `port` `username` `folder` `parentHostId` `tags`
`pin` `sortOrder` `authType` `useWarpgate` `shareSshAuth`
`forceKeyboardInteractive` `password` `key` `keyPassword` `keyType`
`sudoPassword` `autostartPassword` `autostartKey` `autostartKeyPassword`

`authType` is **NOT NULL**, which is why creating a host with only a credential id
fails. `parentHostId` nests a host under another as an organisational parent and
is mutually exclusive with `folder`.

The on-disk database may be encrypted (`db.sqlite.encrypted`); do not plan on
reading or writing it directly.
