---
name: feedback-ghostty-config
description: Ghostty config syntax gotchas — inline comments and audible-bell
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e5210182-2201-4d3d-9dc8-d8a02d45b39f
---

When editing Ghostty config files (`~/Library/Application Support/com.mitchellh.ghostty/config*` on macOS):

1. **No inline comments after values.** Ghostty parses `key = value   # note` as `value = "value   # note"`. Always put comments on their own line above the key. This bit me once and produced 9 cryptic "invalid value" errors that referenced the comment text.

2. **There is no `audible-bell` option.** To silence the bell, use `bell-features = no-system,no-audio,no-attention,no-title,no-border`. The `bell-features` knob controls every bell modality at once.

3. The user's config file is named `config.ghostty` (with extension) at `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` — Ghostty reads it despite the non-standard name. Don't rename it.

**Why:** the user hit these issues live and couldn't copy/paste the validation errors out of the Ghostty UI, so each iteration costs them a manual restart. Avoid the cycle by getting it right the first time.

**How to apply:** before writing any new `.ghostty` config, run `ghostty +show-config 2>&1 | grep -iE "(error|warn|invalid|unknown)"` to surface validation errors yourself. Use `ghostty +show-config --default --docs > /tmp/ghostty-docs.txt` to look up exact option names and accepted values rather than guessing.
