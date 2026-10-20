# Running the environment on your own computer

The class environment is built to run in a **GitHub Codespace**, and that is the
supported setup. If you are comfortable with Docker, you can run the same image
on your own Mac, Windows or Linux machine instead. Nothing is installed on your
computer except Docker; all the tools stay inside the container.

**This is optional and unsupported.** If something here doesn't work, use a
Codespace for your assignments and debug the local setup on your own time.

## What to expect

| | |
|---|---|
| Image | `ghcr.io/dvanblerkom/ece4203:v2027.1.0` (the exact tag is in [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json)) |
| Download | about **2.4 GB** compressed; **7–8 GB** of disk once unpacked. Only the first start downloads it |
| Architecture | **x86-64 (amd64) only.** On Apple Silicon Macs it runs under Rosetta emulation (see below) |
| Resources | at least 2 CPUs and 8 GB of RAM for Docker, and 32 GB of free disk, the same as a Codespace |
| Desktop | noVNC at <http://localhost:6080>, password `ece4203` |

The first start is slow because of the download. On a slow or campus Wi-Fi
connection it can take a long time; start it somewhere with a fast connection
and let it finish. After that the image is cached and the container starts in
seconds.

## 1. Install Docker

| OS | What to install | Settings to check |
|---|---|---|
| **macOS** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | **Settings → Resources**: Memory ≥ 8 GB, disk limit ≥ 64 GB. Apple Silicon: **Settings → General → "Use Rosetta for x86_64/amd64 emulation on Apple Silicon"** must be on |
| **Windows 10/11** | [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the **WSL 2** backend, plus a WSL Ubuntu distribution (`wsl --install`) | **Settings → Resources → WSL integration**: enable your Ubuntu distribution. Memory for WSL 2 is set in `%UserProfile%\.wslconfig` (`[wsl2]` / `memory=8GB`) |
| **Linux** | [Docker Engine](https://docs.docker.com/engine/install/) (Docker Desktop also works) | Add yourself to the `docker` group (`sudo usermod -aG docker $USER`, then log out and back in) |

Check that it works: `docker run --rm hello-world`.

### Apple Silicon (M1/M2/M3/M4) Macs

The image is only built for x86-64; there is no native ARM version, because
ORFS and OSS CAD Suite publish x86-64 binaries. Docker runs it through Apple's
**Rosetta** translation layer. That works well: on an M1 the tools run at a
reasonable speed. The slow part is the first download, not the emulation.

- Make sure the Rosetta option above is on. Without it Docker falls back to QEMU
  emulation, which is several times slower.
- Docker prints `WARNING: The requested image's platform (linux/amd64) does not
  match the detected host platform (linux/arm64/v8)`. That is expected and
  harmless. Add `--platform linux/amd64` to `docker` commands to silence it.

### Windows

Do everything **inside WSL** (the Ubuntu terminal), not in PowerShell or a
Windows folder:

- Clone the repository into your WSL home directory (`~/ece4203_code_2027`),
  **not** under `C:\` or `/mnt/c/...`. Files on the Windows side are very slow
  to access from the container, and Git for Windows converts line endings to
  CRLF, which breaks the shell scripts and Makefiles (`bad interpreter: /bin/bash^M`).
- If you already cloned it on the Windows side, clone it again from WSL.

## 2. Get the repository

```bash
git clone https://github.com/<you>/ece4203_code_2027.git   # your fork or assignment repo
cd ece4203_code_2027
```

Pull the image once, so the long download happens on its own, where you can see
its progress:

```bash
docker pull --platform linux/amd64 ghcr.io/dvanblerkom/ece4203:v2027.1.0
```

## 3a. Start it with VS Code (recommended)

This is the closest to a Codespace: VS Code reads `.devcontainer/devcontainer.json`,
starts the container, forwards the ports and installs the Verilog extensions.

1. Install [VS Code](https://code.visualstudio.com/) and the
   [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   extension. On Windows also install the
   [WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)
   extension, and open the folder from WSL (`code .` in the Ubuntu terminal).
2. Open the repository folder in VS Code.
3. Click **Reopen in Container** when it offers, or run **Dev Containers: Reopen
   in Container** from the command palette (Ctrl/Cmd+Shift+P).
4. Wait for it to start. The terminal in VS Code is now inside the container,
   in `/workspaces/ece4203_code_2027`, as `user`.
5. Open the desktop: **Ports** tab → port **6080** → globe icon, or go to
   <http://localhost:6080/vnc.html?autoconnect=true&resize=remote>. The password is `ece4203`.

Everything in the [README](../README.md) and the lab instructions then works as
written. Your repository folder is shared with the container, so files you edit
in VS Code, commit, or open on your own computer are the same files the tools see.

The `codespaces` settings (idle timeout, machine size) are ignored locally. The
container keeps running until you close VS Code or stop it in Docker Desktop.

## 3b. Start it with plain Docker (no VS Code)

From the repository folder (on Windows, from the WSL terminal):

```bash
docker run -d --name ece4203 --platform linux/amd64 --init --shm-size=1g \
  -p 127.0.0.1:6080:6080 -p 127.0.0.1:5901:5901 \
  -e VNC_PASSWORD=ece4203 -e VNC_RESOLUTION=1600x900x24 \
  -v "$PWD":/workspaces/ece4203_code_2027 \
  -w /workspaces/ece4203_code_2027 \
  ghcr.io/dvanblerkom/ece4203:v2027.1.0 \
  /usr/local/share/desktop-init.sh sleep infinity
```

- `desktop-init.sh` starts the VNC server and noVNC, then runs `sleep infinity`
  to keep the container alive. (VS Code and Codespaces run it automatically; plain
  Docker does not.)
- `127.0.0.1:` keeps the ports reachable only from your own computer.

Then:

```bash
docker exec -it -u user ece4203 bash -l     # a shell inside the container
```

Open <http://localhost:6080/vnc.html?autoconnect=true&resize=remote> (password
`ece4203`) for the desktop.

| | |
|---|---|
| Stop | `docker stop ece4203` |
| Start again later | `docker start ece4203` |
| Delete the container (your repo files are kept) | `docker rm -f ece4203` |

Anything you save outside `/workspaces/ece4203_code_2027` (for example in
`/home/user`) is lost when you delete the container. Keep your work in the repository.

## Using a native VNC viewer instead of the browser

Port 5901 is the VNC server itself. A native viewer gives you a real clipboard
and smoother scrolling:

- **macOS:** `open vnc://localhost:5901` (built-in Screen Sharing)
- **Windows / Linux:** TigerVNC Viewer or RealVNC Viewer → `localhost:5901`

The password is `ece4203`. In VS Code, port 5901 is forwarded automatically; with
plain Docker, the `-p 127.0.0.1:5901:5901` above does it.

## Troubleshooting

**The download stalls or fails.** Run the `docker pull` from step 2 again; it
resumes from the layers it already has. Make sure Docker has enough disk space
(Docker Desktop: **Settings → Resources → Disk usage limit**).

**Port 6080 is already in use.** Something else on your computer is using it.
With plain Docker, change the left side of the mapping (`-p 127.0.0.1:16080:6080`)
and open `localhost:16080` instead. In VS Code, the **Ports** tab shows the local
port it actually picked.

**The desktop page doesn't load.** Inside the container, run
`bash scripts/desktop.sh status`, then `bash scripts/desktop.sh restart`. Logs are
listed in [desktop.md](desktop.md).

**Builds are very slow or get killed.** Give Docker more memory and CPUs (Docker
Desktop: **Settings → Resources**; Windows: `.wslconfig`). ORFS runs on larger
designs need 8 GB or more. On an Apple Silicon Mac, check that Rosetta is on
(see above).

**`Permission denied` on files in the repo (Linux, plain Docker).** The container
user is uid 1000. If your own uid (`id -u`) is different, files created in the
container won't be writable by you, and vice versa. Use VS Code (step 3a), which
adjusts the container user's uid to match yours automatically, or run
`sudo chown -R $(id -u):$(id -g) .` on the host to fix existing files.

**`/bin/bash^M: bad interpreter` (Windows).** The repository was checked out with
Windows line endings. Clone it again from inside WSL (see above).

**Getting a newer image.** When the course image is updated, the tag in
`.devcontainer/devcontainer.json` changes. Pull the new tag (and remove the old one
with `docker image rm` to get the disk space back). In VS Code, run **Dev
Containers: Rebuild Container**.
