# DockyDEB

[![Weekly Update](https://github.com/cloudresty/dockydeb/actions/workflows/weekly-update.yaml/badge.svg)](https://github.com/cloudresty/dockydeb/actions/workflows/weekly-update.yaml)
[![CI](https://github.com/cloudresty/dockydeb/actions/workflows/ci.yaml/badge.svg)](https://github.com/cloudresty/dockydeb/actions/workflows/ci.yaml)
[![GitHub Tag](https://img.shields.io/github/v/tag/cloudresty/dockydeb?label=Version)](https://github.com/cloudresty/dockydeb/tags)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Docker Hub](https://img.shields.io/docker/pulls/cloudresty/dockydeb)](https://hub.docker.com/r/cloudresty/dockydeb)

&nbsp;

DockyDEB is a Debian-based debugging container from [Cloudresty.com](https://cloudresty.com) — a full toolkit for debugging sessions of every kind: networking, DNS, TLS, processes, syscalls, storage and data stores, in a comfortable zsh shell.

&nbsp;

It is built on **Debian trixie**, so it runs the same **glibc** as most production images. That matters when you are debugging: a musl-based container can resolve DNS differently from the glibc application you are trying to diagnose, and `strace`, `ltrace` and `gdb` behave differently against glibc binaries. What you observe in DockyDEB is what your workload experiences.

&nbsp;

The image is **rebuilt every week** and republished only when its contents actually change, so a running DockyDEB carries current Debian security updates rather than whatever was current at the last manual release.

DockyDEB can be used locally or in a Kubernetes cluster as a shell pod. Below are some examples of how to use it. If a specific version is required, please use the appropriate tag.

&nbsp;

## Included Tools

### Networking & Connectivity

- `iproute2` — the modern stack: `ip`, `ss`, `tc`
- `net-tools` — `ifconfig`, `netstat`, `route` for familiarity
- `bind9-dnsutils` — `dig`, `host`, `nslookup`; `ldnsutils` adds `drill`
- `curl`, `wget` — HTTP clients and downloads
- `tcpdump`, `ngrep` — packet capture and payload grep
- `nmap`, `hping3` — port scanning and packet crafting
- `netcat-openbsd`, `socat`, `telnet` — raw sockets and relays
- `traceroute`, `tcptraceroute`, `mtr-tiny`, `iputils-tracepath` — path discovery
- `iputils-ping`, `iputils-arping`, `fping` — reachability, including at layer 2
- `iperf3` — throughput measurement
- `iftop`, `iptraf-ng` — live bandwidth by connection
- `iptables`, `nftables`, `ipset`, `ipvsadm`, `conntrack` — packet filtering, NAT and connection tracking, for debugging NetworkPolicy, kube-proxy and IPVS
- `bridge-utils`, `ethtool` — bridges and NIC settings
- `apache2-utils` — `ab` for HTTP benchmarking
- `whois`, `dhcping` — registry lookups and DHCP probing

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

### TLS & Trust

- `openssl` — `s_client`, certificate inspection, key handling
- `ca-certificates` — the system trust store
- `gnupg` — signature and key verification

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

### Processes, Syscalls & Resources

- `procps` — `ps`, `top`, `vmstat`, `free`, `watch`
- `psmisc` — `killall`, `pstree`, `fuser`
- `htop`, `btop` — interactive process viewers
- `lsof` — open files, sockets and the processes holding them
- `strace`, `ltrace` — syscall and library-call tracing
- `iotop`, `ncdu` — I/O by process, disk usage by directory

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

### Files, Text & Binaries

- `ripgrep` (`rg`), `fd-find` (`fd`) — fast search
- `jq` — JSON processing
- `file`, `tree`, `diffutils` — identification, structure, comparison
- `bsdextrautils` — `hexdump`, `column`
- `binutils` — `objdump`, `strings`, `nm`, `readelf` for binary inspection
- `bzip2`, `unzip`, `xz-utils`, `zip`, `zstd` — archives

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

### Data Stores & Transfer

- `postgresql-client` — `psql`
- `redis-tools` — `redis-cli`
- `sqlite3` — local database inspection
- `git`, `rsync` — version control and file transfer

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

### Shell Environment

- `zsh` — the default shell
- Oh My Zsh with auto-suggestions and syntax highlighting
- Powerlevel10K prompt
- `vim`, `nano`, `less`, `tmux`, `moreutils`, `bash-completion`
- Custom welcome message

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

## Image Variants

| Tag | Runs as | Use it when |
| :--- | :--- | :--- |
| `latest`, `vX.Y.Z` | `root` | Default. Full capability, including packet capture. |
| `nonroot`, `vX.Y.Z-nonroot` | UID/GID `65532` | The cluster enforces `runAsNonRoot`. |

Both are published for `linux/amd64` and `linux/arm64`.

The non-root variant exists because Kubernetes refuses an image with a symbolic
user on a pod with `runAsNonRoot: true` — `container has runAsNonRoot and image
has non-numeric user (root), cannot verify user is non-root` — which otherwise
makes `kubectl debug` unusable on hardened workloads. It declares a numeric
`USER`, so it is admitted.

Raw-socket tools (`tcpdump`, `nmap`, `ping`, `hping3`) need `NET_RAW`, and
`iptables`/`conntrack` need `NET_ADMIN`. The non-root variant trades those for
admission into restricted-PodSecurity clusters; grant the capabilities
explicitly if you need them.

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

## Docker Usage

DockyDEB basic usage, suitable for most debugging sessions. This will start a DockyDEB based container with a shell prompt. `zsh` is the image's default command, so there is nothing to append.

&nbsp;

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name dockydeb \
    --hostname dockydeb \
    cloudresty/dockydeb:latest
```

&nbsp;

DockyDEB with a mounted volume, suitable for debugging sessions that require access to local files. This will start a DockyDEB based container with a shell prompt and a mounted volume.

&nbsp;

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name dockydeb \
    --hostname dockydeb \
    --volume /local-directory:/container-directory \
    cloudresty/dockydeb:latest
```

&nbsp;

`zsh` is the default shell, with Oh My Zsh, the Powerlevel10K prompt,
auto-suggestions and syntax highlighting. If you would rather have a plain
shell, append the one you want:

&nbsp;

```bash
docker run --interactive --tty --rm cloudresty/dockydeb:latest bash
```

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

## Kubernetes Shell Pod

DockyDEB can be used as a shell pod in a Kubernetes cluster. This will start a DockyDEB based pod with a shell prompt.

&nbsp;

```bash
kubectl run dockydeb \
    --stdin \
    --tty \
    --rm \
    --restart=Never \
    --namespace=default \
    --image=cloudresty/dockydeb:latest
```

&nbsp;

### Debugging a running pod

Attach DockyDEB to a live pod as an ephemeral container, sharing its network
namespace — so `ss`, `tcpdump` and `dig` see exactly what the workload sees:

&nbsp;

```bash
kubectl debug -it <pod> \
    --image=cloudresty/dockydeb:latest \
    --target=<container>
```

&nbsp;

On a cluster that enforces `runAsNonRoot`, use the non-root variant instead:

&nbsp;

```bash
kubectl debug -it <pod> \
    --image=cloudresty/dockydeb:nonroot \
    --target=<container>
```

&nbsp;

### Debugging a node

```bash
kubectl debug node/<node> -it --image=cloudresty/dockydeb:latest
```

&nbsp;

🔝 [back to top](#dockydeb)

&nbsp;

&nbsp;

---

### Cloudresty

[Website](https://cloudresty.com) &nbsp;|&nbsp; [LinkedIn](https://www.linkedin.com/company/cloudresty) &nbsp;|&nbsp; [BlueSky](https://bsky.app/profile/cloudresty.com) &nbsp;|&nbsp; [GitHub](https://github.com/cloudresty) &nbsp;|&nbsp; [Docker Hub](https://hub.docker.com/u/cloudresty)

<sub>&copy; Cloudresty</sub>

&nbsp;
