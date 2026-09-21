# Fleets, snippets, tunnels and Docker

## Fleets

```bash
termix fleets list
termix fleets create --name "web" --description "edge proxies"
termix fleets add-host <fleetId> <hostId>
termix fleets members <fleetId>
termix fleets exec <fleetId> 'systemctl is-active nginx'
termix fleets remove-host <fleetId> <hostId>
```

`fleets exec` exits non-zero if **any** host failed. The exit code alone does not
tell you which one — read the per-host output. Treat a non-zero exit as a partial
run and enumerate the failures explicitly.

Sequence a sweep as: read-only probe → confirm the member list → mutating command.

## Snippets

```bash
termix snippets create --name "restart-svc" --content-file ./restart.sh \
  --description "restart a unit" --folder ops
termix snippets run <snippetId> --host <hostId> --input UNIT=nginx
```

`--input NAME=VALUE` is repeatable. `--host` has no default; a snippet is not
bound to a host. Prefer `--content-file` over `--content` so the command lives in
version control rather than shell history.

`snippets run` exits with the remote exit code when the snippet reports one,
otherwise `0` on success and `255` on a CLI or API error.

## Tunnels

```bash
termix tunnel list                 # every tunnel with its status and full name
termix tunnel show <hostId>        # tunnels on a host, with their indexes
termix tunnel start <hostId> <index>
termix tunnel stop <fullName>
```

The asymmetry is easy to get wrong: **start** takes a host id plus a numeric
index from `tunnel show`; **stop** takes the full tunnel name from `tunnel list`.

Tunnels require `--enable-tunnel` on the host.

## Docker

```bash
termix docker ps <hostId>
termix docker logs <hostId> <containerId> --tail 100
termix docker start|stop|restart|pause|unpause <hostId> <containerId>
```

Requires `--enable-docker` on the host. Enable a capability on an existing host
with `hosts update`, never by deleting and recreating it — recreating loses the
host id that fleets, snippets and scripts reference.

```bash
termix hosts update <hostId> --enable-docker --enable-file-manager
```

## Scripting pattern

`-q` prints bare ids, which composes cleanly:

```bash
for id in $(termix hosts list --tag web -q); do
  printf '%s ' "$id"
  termix exec "$id" 'uptime -p' || echo "FAILED"
done
```

Output is JSON whenever stdout is not a terminal, so `| jq` works without passing
`--json` explicitly.
