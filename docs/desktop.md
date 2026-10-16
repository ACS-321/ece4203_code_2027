# Desktop (KLayout, OpenROAD GUI) in Codespaces

The Codespace runs a Linux desktop (XFCE) inside a TigerVNC server. You view it in
your browser through noVNC. Both come from the official
[`desktop-lite`](https://github.com/devcontainers/features/tree/main/src/desktop-lite)
devcontainer feature, version 1.2.10.

| What | Where |
|---|---|
| Browser desktop | the **Ports** tab, then port **6080 "Desktop (noVNC)"**, then the globe icon. Or run `desktop url` |
| Password | `ece4203` |
| VNC server | display `:1`, port 5901 (only reachable from inside the container or through a port forward) |
| Helper | `bash scripts/desktop.sh status \| restart \| logs \| url` (the `desktop` alias once `scripts/tool_env.sh` is sourced) |
| Logs | `~/.cache/ece4203-desktop/desktop.log`, `/tmp/container-init.log`, `/tmp/Xtigervnc.log`, `/tmp/noVNC.log`, `~/.vnc/*.log` |

**Tips**
- **Resolution:** open the noVNC side panel (the small tab on the left edge), then **Settings**, then **Scaling mode = Remote resizing**. The desktop then resizes to match your browser window. `desktop url` prints a link that already has `resize=remote` set.
- **Clipboard:** the noVNC side panel has a **Clipboard** text box. Text you paste there goes to the remote clipboard, and text you copy in the desktop appears there. Browsers don't allow noVNC to read your local clipboard directly, so copy/paste always goes through that box.
- **Starting tools:** from a terminal *inside the desktop*, run `klayout -e` or `openroad -gui`. From a VS Code terminal, first run `export DISPLAY=:1`.

## How it starts, and why that's more robust than the 2026 setup

1. The feature's `/usr/local/share/desktop-init.sh` runs as part of the **container entrypoint**, not from a lifecycle command. It starts dbus, then `tigervncserver :1 -fg …`, then noVNC's `novnc_proxy`. Each one runs inside a `while :; do …; sleep 5; done` loop, so if it crashes it comes back within about 5 s.
2. `postStartCommand` runs `scripts/desktop.sh ensure`. That script waits up to 20 s for the desktop to report healthy (VNC port open *and* `GET /vnc.html` returns 200). If it isn't healthy, the script repairs it. The repair starts everything with `setsid nohup`, so nothing is tied to the lifecycle command's session. The script is idempotent, so running it again changes nothing.
3. `~/.vnc/xstartup` is written by `desktop.sh` and runs `dbus-launch --exit-with-session startxfce4`. If you replace that file with your own, `desktop.sh` leaves it alone.

---

## Diagnosing the old (2026) desktop

The 2026 setup is `postStartCommand: bash /workspaces/ece4203_code/scripts/start-vnc.sh`. That runs `vncserver :1` and then `launch.sh … &` (apt noVNC 1.0 / websockify on Ubuntu 22.04). Run these in a VS Code terminal in an affected Codespace, in this order.

**Step 1: Is anything listening?**
```bash
ps -eo pid,etime,args | grep -E '[X]tigervnc|[X]vnc|[w]ebsockify|[l]aunch.sh'
ss -ltnp | grep -E ':5901|:6080'
```
- If nothing is listening on **6080**, websockify isn't running. See **(a)**.
- If nothing is listening on **5901**, the VNC server isn't running. See **(d)**.

**Step 2: Does the web server answer inside the container?**
```bash
curl -sI http://localhost:6080/            | head -1
curl -sI http://localhost:6080/vnc.html    | head -1
curl -s  http://localhost:6080/nonexistent | head -5
```
- If `/vnc.html` returns `200`, the server side is fine and the problem is between your browser and GitHub. See **(b)**.
- If it returns `404` with a body like `Error response … Error code: 404 … File not found`, the 404 is coming from **websockify's built-in web server**. Its `--web` directory is wrong or `vnc.html` is missing. Check with `ls /usr/share/novnc/`.
- If the connection is refused, see **(a)**.

**Step 3: What does the 404 page in the browser look like?**
- If it's a **plain-text** "Error response / File not found" page, it comes from websockify (step 2).
- If it's a **GitHub-styled** page, the Codespaces port-forwarding proxy produced it. Usually that means the port isn't forwarded or is forwarded under a different URL. Check the **Ports** tab: is 6080 listed, and what is its "Running process"? Remove the port and add it back.
- Open the URL that the Ports tab gives you. Don't use a bookmarked one: the hostname changes for every Codespace (`<codespace-name>-6080.app.github.dev`).

### Hypotheses

**(a) Background processes killed when `postStartCommand` exits.** *Most likely cause of "never worked on first start".*
`launch.sh … &` is started with no `nohup` or `setsid`. When the lifecycle command finishes, its process group or session can be torn down and websockify goes with it. That fits "restart by hand fixes it": an interactive terminal stays alive.
- *Check:* run step 1 right after the Codespace opens. Then run `start-vnc.sh` from a terminal, close that terminal, and run step 1 again.
- *Fix:* run the processes outside the lifecycle session (`setsid nohup …`), or start them from the container entrypoint. desktop-lite does both of these.

**(b) Firefox tracking or cookie protection breaking the `*.app.github.dev` sign-in.**
Private forwarded ports authenticate with a redirect through github.com and a cookie on `app.github.dev`. Firefox's Enhanced Tracking Protection (Strict) and Total Cookie Protection, or a privacy extension, can block that cookie. You'll then see a sign-in loop, a blank page, or an error page.
- *Check:* open the same port URL in Chrome, or in a Firefox private window with extensions disabled. Then in Firefox, click the shield icon in the address bar and turn off Enhanced Tracking Protection for `app.github.dev`. As a last-resort test only, set port 6080 to **Public** for a minute (right-click the port, then Port Visibility). If the page loads then, the problem is sign-in or cookies, not the server.
- *Also check:* the browser console (F12) for blocked cookies or redirect errors.

**(c) WebSocket problems in the old apt noVNC/websockify** (noVNC ~1.0 on Ubuntu 22.04).
- *Check:* if `vnc.html` loads but **Connect** fails, open the F12 console and Network tab and look at the `websockify` request. You should see `101 Switching Protocols`. A 4xx or 5xx response, or a console error about a closed WebSocket, points here.
- *Fix:* desktop-lite installs noVNC 1.6.0 from upstream.

**(d) VNC server start failures.**
- *Check:* `ls -la /tmp/.X11-unix /tmp/.X1-lock ~/.vnc/; tail -50 ~/.vnc/*:1.log`
- Leftover `/tmp/.X1-lock` or `~/.vnc/*:1.pid` files make `vncserver :1` refuse to start.
- On TigerVNC 1.11 and newer (Ubuntu 22.04 ships 1.12), **the VNC server exits when the session started by `xstartup` exits**. Without a running system dbus, `xfce4-session` can exit immediately on first boot, and it takes the VNC server down with it. Look for `xfce4-session` or `dbus` errors in `~/.vnc/*.log`.
- *Fix:* desktop-lite starts dbus before the VNC server, deletes stale lock files, and restarts the VNC server whenever it exits.

**Stopgap for a 2026 Codespace** (until students move to the new image). Run this in a terminal:
```bash
vncserver -kill :1 2>/dev/null; pkill -f websockify; rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -geometry 1600x900 -depth 24 -localhost yes
setsid nohup websockify --web /usr/share/novnc 6080 localhost:5901 > /tmp/novnc.log 2>&1 < /dev/null &
curl -sI http://localhost:6080/vnc.html | head -1     # expect: HTTP/1.0 200 OK
```

---

## Alternatives considered

| | **desktop-lite (chosen)** | KasmVNC | Xpra HTML5 | 2026 setup (TigerVNC + apt noVNC) |
|---|---|---|---|---|
| Maintained for Codespaces | Yes, by the devcontainers/Codespaces team | No (Kasm targets its own platform) | No | No |
| Startup | Container entrypoint, with keep-alive loops | Its own service; needs a user DB and TLS settings | Its own service | `postStartCommand &` (fragile) |
| Firefox / Chrome / Safari | All three (plain noVNC, WebSocket over the GitHub HTTPS proxy) | All three, but needs its own TLS/auth settings to work behind the GitHub proxy | All three; worked by others in Codespaces but not documented | All three when it runs |
| Clipboard | Through the noVNC side panel (text) | Best: direct clipboard in Chromium-based browsers | Good, direct in most browsers | Through the noVNC panel |
| Resolution | Follows the browser window with "Remote resizing" | Follows the browser window | Per-window, native size | Fixed at 1280×800 |
| KLayout / OpenROAD GUI (Qt + OpenGL) | Works (Mesa llvmpipe in Xvnc; see the PR for the test) | Should work (Xvnc-based) | Per-window GL forwarding is less proven | Works |
| Effort / risk | Low: one line in devcontainer.json | Medium–high | Medium | — |

**Plan B, if desktop-lite turns out flaky in Codespaces: KasmVNC.** It handles clipboard and slow links better, but it needs its own auth and TLS configuration to work behind the GitHub port proxy.

## Fallbacks that don't use a browser

You need the [GitHub CLI](https://cli.github.com/) on your own computer: run `gh auth login` once, and `gh codespace list` shows the Codespace name.

**1. Your own VNC client through a port tunnel** (recommended fallback)
```bash
gh codespace ports forward 5901:5901 -c <codespace-name>
# leave that running, then connect a VNC viewer to localhost:5901 (password ece4203)
#   macOS:   open vnc://localhost:5901         (built-in Screen Sharing)
#   Windows/Linux: TigerVNC Viewer or RealVNC Viewer -> localhost:5901
```
You get native clipboard and you can resize. KLayout runs at the same speed as in the browser, or faster.

**2. X11 forwarding over `gh codespace ssh`** (each app gets its own window on your desktop)
```bash
gh codespace ssh -c <codespace-name> -- -X       # or -Y
klayout -e &
```
- This needs an X server on your computer: **XQuartz** on macOS, **VcXsrv** or **X410** on Windows (or WSLg from a WSL shell), and nothing extra on Linux.
- The `sshd` feature in `devcontainer.json` provides the SSH server.
- OpenGL over SSH is slow and sometimes broken. If KLayout draws badly, try `export LIBGL_ALWAYS_SOFTWARE=1` before starting it.
- This is the least robust option. Use it only if VNC is unavailable.
