# DockyDEB

[![Weekly Update](https://github.com/cloudresty/dockydeb/actions/workflows/weekly-update.yaml/badge.svg)](https://github.com/cloudresty/dockydeb/actions/workflows/weekly-update.yaml)
[![CI](https://github.com/cloudresty/dockydeb/actions/workflows/ci.yaml/badge.svg)](https://github.com/cloudresty/dockydeb/actions/workflows/ci.yaml)
[![GitHub Tag](https://img.shields.io/github/v/tag/cloudresty/dockydeb?label=Version)](https://github.com/cloudresty/dockydeb/tags)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Docker Hub](https://img.shields.io/docker/pulls/cloudresty/dockydeb)](https://hub.docker.com/r/cloudresty/dockydeb)

&nbsp;

DockyDEB is a Debian-based Docker image from [Cloudresty.com](https://cloudresty.com) packaged with a small set of tools for quick and easy debugging sessions.

DockyDEB can be used locally or in a Kubernetes cluster as a shell pod. Below are some examples of how to use it. If a specific version is required, please use the appropriate tag.

&nbsp;

## Included Tools

DockyDEB includes a comprehensive set of debugging and system administration tools:

### Network & Connectivity

- `curl`, `wget` - Download tools and HTTP clients
- `dnsutils` - DNS lookup tools (nslookup, dig)
- `iputils-ping` - Network ping utility
- `net-tools` - Network configuration tools
- `telnet` - Terminal network protocol

🔝 [back to top](#dockydeb)

&nbsp;

### System Monitoring & Management

- `htop` - Interactive process viewer
- `btop` - Modern system monitor
- `ncdu` - Disk usage analyzer

🔝 [back to top](#dockydeb)

&nbsp;

### Development & Text Processing

- `git` - Version control system
- `vim` - Text editor
- `jq` - JSON processor
- `unzip`, `zip` - Archive utilities

🔝 [back to top](#dockydeb)

&nbsp;

### Shell Environment

- `zsh` - Advanced shell (default)
- Oh My Zsh - ZSH framework with plugins
- Powerlevel10K theme - Beautiful terminal prompt
- Auto-suggestions and syntax highlighting
- Custom welcome message

🔝 [back to top](#dockydeb)

&nbsp;

## Docker Usage

DockyDEB basic usage, suitable for most debugging sessions. This will start a DockyDEB based container with a shell prompt.

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name dockydeb \
    --hostname dockydeb \
    cloudresty/dockydeb:latest zsh
```

&nbsp;

DockyDEB with a mounted volume, suitable for debugging sessions that require access to local files. This will start a DockyDEB based container with a shell prompt and a mounted volume.

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --name dockydeb \
    --hostname dockydeb \
    --volume /local-directory:/container-directory \
    cloudresty/dockydeb:latest zsh
```

🔝 [back to top](#dockydeb)

&nbsp;

## Kubernetes Shell Pod

DockyDEB can be used as a shell pod in a Kubernetes cluster. This will start a DockyDEB based pod with a shell prompt.

```bash
kubectl run dockydeb \
    --stdin \
    --tty \
    --rm \
    --restart=Never \
    --image=cloudresty/dockydeb:latest \
    --command -- zsh
```

🔝 [back to top](#dockydeb)

&nbsp;

---

&nbsp;

Brought to you by the [Cloudresty](https://cloudresty.com) team.

[Website](https://cloudresty.com) &nbsp;|&nbsp; [LinkedIn](https://www.linkedin.com/company/cloudresty) &nbsp;|&nbsp; [BlueSky](https://bsky.app/profile/cloudresty.com) &nbsp;|&nbsp; [GitHub](https://github.com/cloudresty) &nbsp;|&nbsp; [Docker Hub](https://hub.docker.com/u/cloudresty)

&nbsp;
