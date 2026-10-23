# tmux cheatsheet

Shortcuts for **this specific config** (macOS only): tmux as the host for
tmux-claude-hatch, our fork of craftzdog's. For the full reference, `man tmux`.

`prefix` = **`C-t`** (Ctrl+t, release, then the key; `C-t C-t` sends a real Ctrl+t
through, e.g. to fzf's file widget). `M-x` = Alt+x with the **left ⌥**
(Ghostty's `macos-option-as-alt = left`); the `M-` keys need no prefix.

Every binding below is taken from `tmux/tmux.conf` or the plugin's scripts.
After editing `tmux.conf`: **`C-t r`** reloads it.

---

## 1. Claude (tmux-claude-hatch)

Each Claude lives in a detached `claude-<hash>` session per directory, shown in a
popup over your window. Closing the popup leaves it running; the same key
re-attaches.

### Launch

| Shortcut | Action |
|---|---|
| `M-y` | Claude for the pane's directory, **subscription** (launch or re-attach) |
| `M-a` | The same on the **API key**: `caffeinate -di claude-api-env claude` |
| `M-Y` | Asks for a worktree name, then `claude --worktree <name>`, subscription |
| `M-A` | The same worktree prompt, API key |
| `M-d` | Close the Claude popup (the session keeps running). Outside a popup it goes to the program (zsh's kill-word) |
| `C-t y` / `C-t u` | The plugin's own launch / picker keys, still bound |

The subscription and the API key get **separate sessions**: one directory can run
both at once. The API ones are labelled `api` in the picker. Without
`~/.claude/claude-api.env` an API launch fails and the popup holds the error
until Enter.

### The picker — `M-u`

Every Claude running in a tmux pane, `working` / `waiting` / `idle`, grouped by
repository (a worktree under its main checkout), with a live preview.

| Key | Action |
|---|---|
| `enter` | Jump to it: a hatch Claude opens in a popup over the window that launched it, a loose one in its own pane |
| `ctrl-x` | Kill that Claude |
| `ctrl-r` | Label it (an empty label removes it); the label titles its popup |
| `ctrl-y` | Copy its location (`session:window.pane`) for `tmux send-keys -t` |
| `esc` | Close the picker |

### Worktrees — `M-U`

The worktrees of the pane's repository: the main checkout, Claude's
`.claude/worktrees/*` and any `git worktree add`. `●` where a subscription Claude
runs, `api` where an API one does, `changes` for uncommitted work; the preview
shows status and the last commits.

| Key | Action |
|---|---|
| `enter` | Claude on that worktree, subscription (re-attaches when alive) |
| `ctrl-a` | The same on the API key |
| `esc` | Close |

From a shell: `git worktree list`.

### Worktree names (for `M-Y` / `M-A`)

Claude Code owns the worktree, exactly as with `claude --worktree`:

| You type | What you get |
|---|---|
| `feat-x` | `.claude/worktrees/feat-x/` on branch `worktree-feat-x`, from the default branch; reopened if it exists |
| `#1234` or a PR URL | That pull request, fetched from `origin` |

On exiting Claude: a worktree with no changes is removed; with changes (or a
session you `/rename`d) Claude asks keep or remove. Killing it (`ctrl-x`)
leaves the worktree in place.

---

## 2. Windows (the "tabs")

They are listed in the status bar at the bottom; a click there switches too.

| Shortcut | Action |
|---|---|
| `C-t c` | New window, in the pane's directory |
| `C-t 1` … `C-t 9` | Go to window N (numbered from 1) |
| `C-t n` / `C-t p` | Next / previous window |
| `C-t ,` | Rename the window |
| `C-t &` | Close the window (asks); `exit` in its last pane does the same |
| `C-t w` | Tree of every session and window, enter jumps |

## 3. Panes (splits)

| Shortcut | Action |
|---|---|
| `C-t v` | Split side by side (like Ghostty's `⌘B v`) |
| `C-t s` | Split top / bottom (like `⌘B s`). Not the session list here |
| `C-t h` / `j` / `k` / `l` | Move to the pane left / down / up / right |
| `C-t z` | Zoom the pane (again to restore) |
| `C-t x` | Close the pane (asks) |
| Mouse | Click selects a pane, drag a border resizes |

## 4. Sessions

| Shortcut / command | Action |
|---|---|
| `C-t w` | Choose a session or window (`C-t s` is the split here) |
| `C-t $` | Rename the session |
| `C-t d` | Detach: tmux keeps running, you're back in the plain shell |
| `tmux new -s <name>` | New named session |
| `tmux a` / `tmux a -t <name>` | Re-attach the last / a named session |
| `tmux ls` | List sessions (the `claude-*` ones are the hatch's) |
| `tmux kill-session -t <name>` | End a session |

Inside tmux the zsh prompt opens with **`tmux:<session>`**, so a tmux shell
never passes for a plain Ghostty one.

## 5. Copy and scroll

| Shortcut | Action |
|---|---|
| Mouse wheel | Scroll back (enters copy mode) |
| `C-t [` | Copy mode by keyboard, vi keys (`/` searches, `q` leaves) |
| `Space` … `Enter` | Start a selection, copy it (in copy mode; `v` toggles a block selection) |
| Mouse drag | Select and copy |

Copies reach the macOS clipboard (OSC 52 through Ghostty), from a Claude popup too.
