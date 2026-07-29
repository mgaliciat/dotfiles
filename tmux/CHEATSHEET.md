# tmux cheatsheet

Commands relevant to **this config**. `prefix` = `Ctrl+t`.

Convention: `prefix x` = you press `Ctrl+t`, release, then `x`.

`prefix C-t` (that is, `Ctrl+t` twice) sends a **literal** `Ctrl+t` to the pane — the escape hatch for nested tmux or apps that want that key.

---

## ⭐ The most important part (the popups — single chord, no prefix)

| Shortcut | Action |
|---|---|
| `Alt+c` | **Claude Code in a 90% popup** — persistent "default" session per project |
| `Alt+C` | **Claude YOLO** — same as `Alt+c` but with `--dangerously-skip-permissions` (separate session) ⚠️ |
| `Alt+u` | **Central picker of Claude sessions** (session-manager plugin) — ALL sessions, live working/waiting/idle state + preview |
| `Alt+y` | **Claude launcher per directory** (session-manager plugin) |
| `Alt+d` | **Close the Claude popup** (safe detach — only if you're inside a `claude*` session) |
| `Alt+g` | **lazygit in a 90% popup** — floating git UI in the cwd |
| `Alt+Enter` | Quick shell in a 90% popup — for one-off commands without taking up a pane |
| `prefix b` | **Toggle the statusline** on/off (default: OFF, no distraction) |

**When to use `Alt+C` (YOLO) vs `Alt+c` (normal):**
- `Alt+c` → daily workflow. Claude asks for confirmation before each bash/edit. Safer.
- `Alt+C` → massive refactors, quick exploration, sandbox repos. Claude runs everything without asking. **Only in versioned repos or ones you can throw away.**
- The sessions are different (`claude-<hash>` vs `claude-yolo-<hash>`) → the context doesn't mix.

**When to use `Alt+u`/`Alt+y` (plugin) vs `Alt+c`/`Alt+C`:**
- `Alt+c`/`Alt+C` → they give you the project's "default" session. Just one.
- `Alt+u` → central picker: it lists ALL of the server's Claude sessions (from every project) with live state (working/waiting/idle, via `claude agents --json`) and preview. It replaced the old `Alt+s` selector.
- `Alt+y` → the plugin's per-directory launcher. For the same dir it resolves to the **same** `claude-<hash>` session as `Alt+c` (same md5 algorithm) — they're shared, not duplicated. Also a popup; the only difference is it records the origin window so the picker can jump back.

**How the Claude session works:**
1. `cd ~/projects/foo` → `Alt+c` → a `claude-<md5>` session is created with Claude running, and a 90% popup attaches to it.
2. You close the popup with `Alt+d` → Claude stays alive in the background.
3. You come back later to `~/projects/foo` → `Alt+c` → you reattach to the **same** session with all its context.
4. You switch to `~/projects/bar` → `Alt+c` → a DIFFERENT session (different md5).
5. Lost track of which Claude is running where? → `Alt+u` → picker with the live state of all of them.

**Session naming convention:**
- `claude-<hash>` → the default one that `Alt+c` / `Alt+y` open (they share the hash)
- `claude-yolo-<hash>` → the YOLO default that `Alt+C` opens

To list the active Claude sessions: `tmux ls | grep claude` (or `Alt+u`).
To kill a specific session: `tmux kill-session -t claude-<hash>`.

---

## Sessions (persistence — the main reason for tmux)

| Shortcut / Command | Action |
|---|---|
| `tmux new -s name` | Create a named session |
| `tmux ls` | List the active sessions |
| `tmux a` or `tmux attach` | Attach to the last session |
| `tmux a -t name` | Attach to a specific session |
| `prefix d` | **Detach** — you leave tmux, the session stays alive |
| `prefix s` | Session selector (with preview) |
| `prefix $` | Rename the current session |
| `tmux kill-session -t name` | Kill a session |
| `tmux kill-server` | Kill ALL of tmux (careful) |

**Typical workflow:**
1. `tmux new -s work` → you start working.
2. You close Ghostty (by accident or on purpose) → the session persists.
3. You open Ghostty again → `tmux a -t work` → everything as it was.
4. Full reboot → `tmux-resurrect` restores panes + commands (auto via `tmux-continuum`).

---

## Windows (tabs inside the session)

| Shortcut | Action |
|---|---|
| `prefix c` | Create a new window |
| `prefix ,` | Rename the current window |
| `prefix &` | Close the window (asks for confirmation) |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix <num>` | Go to window N (`prefix 1`, `prefix 2`, ...) |
| `prefix w` | Window selector with preview |
| `C-S-Left` / `C-S-Right` | Move the window in the order (no prefix, instant) |
| `prefix f` | Search across all windows by text |

---

## Panes (splits)

| Shortcut | Action |
|---|---|
| `prefix \|` | Vertical split (cwd preserved) |
| `prefix -` | Horizontal split (cwd preserved) |
| `prefix h/j/k/l` | Navigate to the left/down/up/right pane |
| `prefix H/J/K/L` | Resize the pane (via tmux-pain-control) |
| `prefix z` | Zoom in/out on the current pane (fullscreen toggle) |
| `prefix x` | Close the current pane (with confirmation) |
| `prefix e` | Close all the **other** panes of the window — the current one survives (`kill-pane -a`, no confirm) |
| `prefix {` / `prefix }` | Swap the pane with the previous / next one |
| `prefix q` | Show the pane numbers (then `<num>` to go there) |
| `prefix !` | Turn the current pane into its own window |
| `prefix Space` | Rotate the layout (even-horizontal, tiled, etc.) |

---

## Copy mode (vi mode)

You enter with `prefix [`. You exit with `q`.

| Shortcut (inside copy mode) | Action |
|---|---|
| `h j k l` | Navigate |
| `w` / `b` | Next / previous word |
| `g` / `G` | Start / end of the buffer |
| `/` / `?` | Search forwards / backwards |
| `n` / `N` | Next / previous match |
| `v` | Start the selection |
| `y` | **Copy to the system clipboard** (via pbcopy) |
| `Enter` | Copy and exit |

**To paste** what you copied (in any pane): `prefix ]`.

---

## Config

| Shortcut / Command | Action |
|---|---|
| `prefix r` | **Reload the config** (without killing the session) |
| `prefix o` | Open `pane_current_path` in Finder |
| `prefix g` | **IDE layout** — builds 4 panes (main + right column, terminal 30% at the bottom, sidebar 20% at full height); it doesn't launch apps, just the layout |
| `prefix ?` | List ALL the keybindings (`q` to exit) |
| `prefix t` | Clock in a fullscreen pane (aesthetic) |

---

## Plugins (tpm)

You edit the list in `tmux/tmux.conf` (the `# ─── plugins` section) and:

| Shortcut | Action |
|---|---|
| `prefix I` (uppercase) | **Install** new plugins |
| `prefix U` (uppercase) | **Update** plugins |
| `prefix alt+u` | Uninstall plugins removed from the config |

Current plugins:
- `tmux-pain-control` — `prefix h/j/k/l` to navigate, `prefix H/J/K/L` to resize
- `tmux-resurrect` — `prefix Ctrl+s` save, `prefix Ctrl+r` restore (survives reboots)
- `tmux-continuum` — auto-save of resurrect every 15 min + auto-restore on start
- `tmux-claude-session-manager` — picker/launcher of Claude sessions (rebound to `Alt+u` / `Alt+y`, see above)

---

## Mouse

Enabled by default. You can:
- **Click** on a pane → selects it
- **Click** on a window (statusline) → selects it
- **Drag** on a pane border → resize
- **Scroll wheel** → enters copy mode and you scroll
- **Drag** over text → visual selection (release = copy)

If it bugs you: in `tmux.conf` change `set-option -g mouse on` → `off`.

---

## Tips

- **`prefix` feels slow at first** — after 1 day it becomes automatic.
- **`prefix d` (detach) is your friend.** Any session you want to "pause" gets detached. You come back with `tmux a -t <name>`.
- **Each project, its session.** A useful convention: `tmux new -s project-name` when you start. Then `tmux ls` shows you the context.
- **So you don't lose hacks:** everything you touch at runtime (split, layout) is lost when you kill the session unless `tmux-resurrect` saves it. `prefix Ctrl+s` to force a save.
- **If a shortcut doesn't work:** `prefix ?` shows everything that's bound. `:list-keys` too.
- **To leave tmux completely without killing it:** `prefix d`. NEVER close the terminal with active sessions you don't want to lose — always detach first.
