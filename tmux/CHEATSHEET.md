# tmux cheatsheet

Shortcuts for **this specific config** (macOS only). For the full reference,
`man tmux`.

Every Ghostty tab, split and quick terminal starts inside tmux, in a session of
its own. Leaving tmux (`exit` in its last pane, or a detach) closes the tab,
and closing the tab (`⌘W`, the window, quitting Ghostty) ends its session and
what runs in it. Only the `claude-*` sessions outlive a tab, for up to 15
days without use.
`export NO_AUTO_TMUX=1` in `~/.zshenv.local` turns that off on one machine.

`prefix` = **`C-t`** (Ctrl+t, release, then the key; `C-t C-t` sends a real Ctrl+t
through, e.g. to fzf's file widget). `M-x` = Alt+x with the **left ⌥**
(Ghostty's `macos-option-as-alt = left`); the `M-` keys need no prefix.

Every binding below is taken from `tmux/tmux.conf`, `tmux/claude-popup.sh` or
the plugin's scripts; `tmux/reap-sessions.sh` is what ends a closed tab's
session and a forgotten Claude.
After editing `tmux.conf`: **`C-t r`** reloads it.

---

## 1. Claude (tmux-claude-hatch)

Each Claude lives in a detached `claude-…` session per directory, shown in a
popup over your window. Closing the popup leaves it running; the same key
re-attaches. While it runs the Mac stays awake (`caffeinate -di`).

A Claude you have not opened or typed in for **15 days** is closed on its own
(`@claude_idle_days` in `tmux.conf`; 0 turns that off). The conversation
stays: `claude --resume` in that directory picks it up.

### Launch

| Shortcut | Action |
|---|---|
| `M-c` | Claude for the pane's directory (launch or re-attach) |
| `M-a` | `M-c` through the **API gateway**: `claude-api-env claude` |
| `M-d` | Close the Claude popup (the session keeps running). Outside a popup it goes to the program (zsh's kill-word) |

The two get **separate sessions**: one directory can run both side by side.
Without a valid `~/.claude/claude-api.env` an API launch does not start, and
tmux's message line says why.

### With arguments, a worktree first of all

`C-t` before either launch key asks for Claude's arguments first.
tmux's bottom line shows the command that key runs, with `-w ` already typed:

```
caffeinate -di claude -w ▏
```

Type the worktree name and `Enter`: `caffeinate -di claude -w name-wt` starts
in a popup, and Claude Code makes (or reopens) that git worktree itself.

| Shortcut | The line you finish |
|---|---|
| `C-t M-c` | `caffeinate -di claude -w …` |
| `C-t M-a` | `caffeinate -di claude-api-env claude -w …` |

- The line is yours to edit: `C-u` clears the `-w ` for other arguments
  (`-c`, `--resume`, a quoted prompt). It is read like a shell line, so
  `-w '#1234'` needs its quotes.
- Each distinct line is a **session of its own**, beside the directory's plain
  `M-c`: one repo can run a Claude per worktree. The popup's title carries the
  arguments.
- To come back: the same key and the same line (`↑` at the prompt recalls it),
  or the `M-u` picker.
- `Esc` cancels; nothing typed is the plain launch.
- A command that ends at once (`-w` outside a git repo, a directory not yet
  trusted, a mistyped flag) stays on screen until `Enter`.

### The picker — `M-u`

Every Claude running in a tmux pane, `working` / `waiting` / `idle`, with a
live preview. The ones that need you sort to the top.

| Key | Action |
|---|---|
| `enter` | Jump to it: a popup Claude opens over the window that launched it, one started by hand in its own pane |
| `ctrl-x` | Kill that Claude |
| `ctrl-y` | Copy its location (`session:window.pane`) for `tmux send-keys -t` |
| `esc` | Close the picker |

`C-t u` is the plugin's own key for the same picker.

---

## 2. Popups

| Shortcut | Action |
|---|---|
| `M-g` | lazygit in the pane's directory (`q` closes it) |
| `M-Enter` | A shell in the pane's directory (`exit` closes it) |

## 3. Windows

A tab starts with one. The status bar that lists them is off; `C-t b` toggles
it.

| Shortcut | Action |
|---|---|
| `C-t c` | New window, in the pane's directory |
| `C-t 1` … `C-t 9` | Go to window N (numbered from 1) |
| `C-t n` / `C-t p` | Next / previous window |
| `C-t ,` | Rename the window |
| `C-t &` | Close the window (asks); `exit` in its last pane does the same |
| `C-t w` | Tree of every session and window, enter jumps |
| `C-t b` | Show / hide the status bar |

## 4. Panes (splits)

| Shortcut | Action |
|---|---|
| `C-t v` or `C-t \|` | Split side by side (like Ghostty's `⌘B v`) |
| `C-t s` or `C-t -` | Split top / bottom (like `⌘B s`). Not the session list here |
| `C-t h` / `j` / `k` / `l` | Move to the pane left / down / up / right |
| `C-t z` | Zoom the pane (again to restore) |
| `C-t x` | Close the pane (asks) |
| Mouse | Click selects a pane, drag a border resizes |

## 5. Sessions

| Shortcut / command | Action |
|---|---|
| `C-t w` | Choose a session or window (`C-t s` is the split here) |
| `C-t $` | Rename the session |
| `C-t d` | Detach: the tab closes and its session ends |
| `tmux ls` | List sessions (numbers are open tabs, `claude-*` the popups') |
| `tmux kill-session -t <name>` | End a session |

A `claude-*` session lives until its Claude exits (`/exit`, or `ctrl-x` in the
`M-u` picker) or it has gone 15 days without use, tab or no tab, and keeps the
Mac awake meanwhile. The picker is where a forgotten one shows up, with its
age.

## 6. Copy and scroll

| Shortcut | Action |
|---|---|
| Mouse wheel | Scroll back (enters copy mode) |
| `C-t [` | Copy mode by keyboard, vi keys (`/` searches, `q` leaves) |
| `v` … `y` | Start a selection, copy it (in copy mode) |
| Mouse drag | Select and copy |

Copies reach the macOS clipboard (OSC 52 through Ghostty), from a Claude popup too.
