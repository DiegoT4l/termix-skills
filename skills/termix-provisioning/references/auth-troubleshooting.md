# "All configured authentication methods failed"

Termix reports the same message for every key failure. Work the tree in order;
each step is cheap and eliminates a whole class.

## 0. Read the connection log

```
Connecting to HOST port 22
Using SSH key authentication
Authenticating as root
ERROR Connection error: All configured authentication methods failed
```

Reaching `Authenticating as` proves the network path and any IP ban are fine —
a firewall drop or `fail2ban` would cut the TCP connection first. The problem is
the key.

## 1. Compare fingerprints — do this before any other hypothesis

Termix derives the public key from the private key it holds and exposes it:

```bash
termix credentials get <id>            # take the publicKey line
echo "<publicKey> label" > /tmp/k.pub && ssh-keygen -lf /tmp/k.pub
```

On the target:

```bash
ssh-keygen -lf ~/.ssh/authorized_keys
```

No match means the key was never authorized. Stop here and authorize it; every
other hypothesis is wasted effort.

## 2. Metadata already answers two hypotheses

`termix credentials get <id>` reports:

- `hasKeyPassword: no` with a populated `detectedKeyType` → the key parsed without
  a passphrase, so a missing passphrase is NOT the cause.
- `detectedKeyType: ssh-ed25519` → the legacy-RSA problem below does not apply.

## 3. Server-side ownership: the silent one

`StrictModes yes` is the OpenSSH default. sshd **ignores `authorized_keys`
without logging why** when ownership or permissions are loose:

- `~/.ssh` must be owned by the account, mode `700`.
- `authorized_keys` must be owned by the account, not group/world writable.
- Every parent directory must be owned by the account or root.

Diagnose by comparing against a host that works:

```bash
stat -c '%n uid=%u gid=%g %A' /root /root/.ssh /root/.ssh/authorized_keys
```

A uid of `100000` (or any value above `65535`) where `0` is expected means a
container id-shift leaked onto disk. Typical cause: a container converted between
privileged and unprivileged without remapping ownership. Fix:

```bash
chown -R root:root /root /root/.ssh && chmod 700 /root/.ssh
```

If the whole filesystem is shifted, remap by subtracting the offset rather than
blanket-chowning, or legitimate non-root accounts are destroyed:

```bash
for u in $(find / -xdev -uid +99999 -printf '%U\n' | sort -u); do
  find / -xdev -uid "$u" -exec chown -h "$((u-100000))" {} +
done
```

Snapshot first. Never convert a container's privilege level before remapping: a
backup stores the shifted ownership and the restore applies the offset again.

## 4. Algorithm mismatch

Modern sshd ships `pubkeyacceptedalgorithms` without `ssh-rsa` (SHA-1). A Node
`ssh2` client may still sign an RSA key with the legacy algorithm, and the server
rejects it with this exact message. Confirm:

```bash
sshd -T | grep pubkeyacceptedalgorithms
```

Use an ed25519 key and the class disappears.

## 5. Server policy

```bash
sshd -T | grep -E '^(permitrootlogin|pubkeyauthentication|authorizedkeysfile)'
grep -cE '^(from=|command=|restrict)' ~/.ssh/authorized_keys
```

`authorizedkeysfile` may point somewhere other than `.ssh/authorized_keys`, and
`from=` restrictions silently exclude the Termix host's address.

## Distributing a key to hypervisor guests

Authorizing a key on a hypervisor covers the hypervisor only. On Proxmox,
`/root/.ssh/authorized_keys` is a symlink to `/etc/pve/priv/authorized_keys`,
which is replicated cluster-wide — so one write covers every node, and **no**
guest. Use `assets/distribute-key.sh` for the guests.
