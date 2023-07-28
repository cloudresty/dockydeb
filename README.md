# DockyDEB

DockyDEB is a Debian-based Docker image from [Cloudresty.com](https://cloudresty.com) packaged with a small set of tools for quick and easy debugging sessions.

DockyDEB can be used locally or in a Kubernetes cluster as a shell pod. Below are some examples of how to use it. If a specific version is required, please use the appropriate tag.

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

&nbsp;

---
Copyright &copy; [Cloudresty](https://cloudresty.com)
