#!/usr/bin/env python3
# ─── PreToolUse hook on Bash: file changes go through Edit/Write ───
#
# Fallback for the Bash-first steer that auto and bypassPermissions mode inject
# (the CLAUDE_CODE_THRIFTY_SONIC block in claude/install/settings.sh turns the
# steer off; this catches what still slips through if that switch ever goes). A
# change made through the shell shows no diff, is not checkpointed for /rewind,
# never loads path-scoped rules or a nested CLAUDE.md, and has no exactly-once
# match on the text it replaces. Edit/Write have all four.
#
# Denies in-place editors (sed -i, perl/ruby -i, awk -i inplace), `>` `>>` `&>`
# and `tee` into a real file, and interpreter code that writes files
# (python -c or a heredoc, node -e, ...). Lets through reads, /dev/*, temp dirs,
# targets held in a variable (unresolvable here), heredocs fed to stdin
# (`git commit -F - <<EOF`), and any command carrying ALLOW_BASH_WRITE=1 — the
# deliberate escape hatch, visible in the command itself.
#
# Heuristic on purpose: it matches the shapes the steer produces, not every way a
# shell can write a file. Python because shlex is what tells a quoted `>` from a
# redirect; bash + jq cannot. Every failure path exits 0 with no output, so a bug
# here can only miss a command, never block one.

import json
import os
import re
import shlex
import sys

ESCAPE = "ALLOW_BASH_WRITE=1"

# `<<` but not the here-string `<<<`, whose word would otherwise be taken for a
# delimiter and swallow every line after it.
HEREDOC = re.compile(r"(?<!<)<<(?!<)(-?)[ \t]*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")

WRITE_API = re.compile(
    r"\.write_(?:text|bytes)\s*\("
    r"|\bopen\s*\([^)]*,\s*(?:mode\s*=\s*)?['\"][rbt]*[wax+]"
    r"|\b(?:writeFileSync|appendFileSync|writeFile|appendFile)\s*\("
    r"|\bFile\.(?:write|open)\s*\("
)

INTERPRETERS = {"python", "python3", "node", "ruby", "perl"}
CODE_FLAGS = {"-c", "-e", "-E", "--eval", "-p", "--print"}
WRAPPERS = {"sudo", "env", "command", "exec", "nohup", "time", "nice", "rtk"}
REDIRECTS = {">", ">>", ">|", "&>", "&>>"}
SEPARATOR_CHARS = set(";&|()\n")
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
# sed takes clustered short flags (-Ei); perl/ruby also take -MModule, whose
# capitals would make a looser pattern read `-MList::Util` as an in-place edit.
SED_IN_PLACE = re.compile(r"^-[A-Za-z]*i|^--in-place")
PERL_IN_PLACE = re.compile(r"^-[a-z]*i")
TEMP_PREFIXES = ("/dev/", "/tmp/", "/private/tmp/", "/var/folders/", "/private/var/folders/")

HOME = os.path.expanduser("~")
TMPDIR = os.environ.get("TMPDIR", "")


def tokenize(text):
    lex = shlex.shlex(text.replace("\\\n", " "), posix=True, punctuation_chars=";&|()<>\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    return list(lex)


def split_heredocs(command):
    """The command without heredoc bodies, plus each body with its opening line."""
    lines = command.split("\n")
    kept, bodies = [], []
    i = 0
    while i < len(lines):
        line = lines[i]
        kept.append(line)
        i += 1
        for strip_tabs, _, delim in HEREDOC.findall(line):
            body = []
            while i < len(lines):
                current = lines[i]
                i += 1
                if (current.lstrip("\t") if strip_tabs else current) == delim:
                    break
                body.append(current)
            bodies.append((line, "\n".join(body)))
    return "\n".join(kept), bodies


def writes_real_file(target):
    if not target or target.startswith("&") or target.isdigit():
        return False
    path = target
    if path == "~" or path.startswith("~/"):
        path = HOME + path[1:]
    path = re.sub(r"^\$\{?HOME\}?", lambda _: HOME, path)
    path = re.sub(r"^\$\{?TMPDIR\}?", lambda _: TMPDIR, path)
    if any(c in path for c in "$`()"):
        return False
    if path.startswith(TEMP_PREFIXES) or (TMPDIR and path.startswith(TMPDIR)):
        return False
    return True


def command_words(tokens):
    """Yield (index, basename) for every token in command position."""
    at_command = True
    for i, tok in enumerate(tokens):
        if set(tok) <= SEPARATOR_CHARS:
            at_command = True
        elif tok in REDIRECTS or (i and tokens[i - 1] in REDIRECTS):
            continue
        elif at_command and not (ASSIGNMENT.match(tok) or tok in WRAPPERS):
            at_command = False
            yield i, os.path.basename(tok)


def args_of(tokens, start):
    for tok in tokens[start + 1:]:
        if set(tok) <= SEPARATOR_CHARS:
            return
        yield tok


def violations(command):
    script, bodies = split_heredocs(command)
    tokens = tokenize(script)
    found = []

    for i, tok in enumerate(tokens):
        if tok in REDIRECTS and i + 1 < len(tokens) and writes_real_file(tokens[i + 1]):
            found.append(f"`{tok} {tokens[i + 1]}`")

    for i, cmd in command_words(tokens):
        args = list(args_of(tokens, i))
        if cmd in ("sed", "gsed") and any(SED_IN_PLACE.match(a) for a in args):
            found.append(f"`{cmd} -i`")
        elif cmd in ("perl", "ruby") and any(PERL_IN_PLACE.match(a) for a in args):
            found.append(f"`{cmd} -i`")
        elif cmd in ("awk", "gawk") and any(a == "inplace" and b == "-i" for b, a in zip(args, args[1:])):
            found.append(f"`{cmd} -i inplace`")
        elif cmd == "tee":
            found += [f"`tee {a}`" for a in args if not a.startswith("-") and writes_real_file(a)]
        elif cmd in INTERPRETERS:
            code = [b for a, b in zip(args, args[1:]) if a in CODE_FLAGS]
            if any(WRITE_API.search(c) for c in code):
                found.append(f"`{cmd}` code that writes files")

    for line, body in bodies:
        if WRITE_API.search(body) and any(cmd in INTERPRETERS for _, cmd in command_words(tokenize(line))):
            found.append("a heredoc script that writes files")

    return found


def main():
    try:
        payload = json.load(sys.stdin)
        command = payload.get("tool_input", {}).get("command") or ""
        if payload.get("tool_name") != "Bash" or ESCAPE in command:
            return
        found = violations(command)
    except Exception:
        return
    if not found:
        return
    reason = (
        f"Blocked: this command changes files through the shell ({', '.join(dict.fromkeys(found))}). "
        "Make file changes with the Edit or Write tool (Read the file first): that keeps the diff "
        "visible, /rewind working and path-scoped rules loaded. If Edit/Write genuinely cannot do "
        "it (binary output, a generated file, one mechanical change across many files), prefix the "
        f"command with {ESCAPE} and say why."
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
