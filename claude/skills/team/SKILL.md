---
name: team
description: Run a task as a team of Claude Code teammates that message each other, share one task list, and each invoke other skills as their step. Use when the user says "team", "equipo", "/team", "paraleliza esto", "spawn teammates", asks for several agents to work at once, or describes work that splits cleanly into independent tracks (review by dimension, competing hypotheses, one module each). Also covers the background observers that watch teammates for scope drift and regressions.
---

# team

Split a task across teammates, give each one its own files and its own skills to
run, and let them talk to each other instead of round-tripping through you.

A teammate is a full Claude Code session with its own context window. That is the
whole reason to reach for one — and the whole reason not to, when the work is
sequential or touches the same files. Before spawning anything, read
[when NOT to](#when-not-to-use-a-team).

## Preconditions — check these first, they fail silently

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` must have been set **when the session
started**. The dotfiles installer writes it into `~/.claude/settings.json`, but a
session that was already running when it landed does not have it: the Agent tool's
`name` parameter is what turns a subagent into a teammate, and that parameter is
fixed at startup.

**The check is the Agent tool's own schema.** If it has no `name` parameter,
agent teams are off in this session — say so and stop. Do not spawn plain
subagents and call them a team; they cannot message each other and there is no
shared task list. The fix is restarting Claude Code, which is the user's call.

Two more ways this is off with no error:

- **Non-interactive (`-p`, Agent SDK).** A named subagent runs as an ordinary
  subagent. There is no team, and nothing says so.
- **A `fork` call, or `isolation` passed on the call itself.** Both bypass the
  teammate path even with a name.

Observers need `CLAUDE_CODE_EXPERIMENTAL_OBSERVER_AGENTS`, same startup rule.
Both flags are also gated server-side, so the variable is necessary and not
sufficient.

## The budget — 4 teammates, and the harness enforces 6

**Plan for at most 4 teammates.** Three focused teammates beat five scattered
ones: token cost scales linearly with teammates, coordination overhead scales
worse, and past a point extra teammates stop making the work faster.

The hard ceiling is `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, which these dotfiles
set to **6** (the harness default is 20). It counts *every* concurrent agent, not
only teammates:

- each teammate is one
- each **observer** is one more, on top of the teammate it watches
- any subagent a teammate spawns is one more again

So 4 teammates with observers is already at the ceiling. Past it the Agent call
is refused outright — *"Concurrent subagent limit reached. Do not retry."* — and
the refusal is not a suggestion. Plan under the cap instead of discovering it.

If the work genuinely needs more, that is a conversation with the user about
raising the env var, not something to route around by spawning in waves.

## How to run a team

**1. Split the work so no two teammates touch the same file.** This is the split
that matters, more than splitting by topic. Two teammates editing one file
overwrite each other — there is no merge. If the work does not split this way, it
is not team work.

**2. Decide the roles and the skills each one runs.** A teammate's step is often
"run this skill on this scope". Name the skill explicitly in the spawn prompt:

```
teammate "security"  → /security-review on src/auth/
teammate "reviewer"  → /code-review on the same diff
teammate "docs"      → /logbook:walkthrough for the login flow
```

**3. Spawn them.** One Agent call per teammate, each with a `name` and
`subagent_type: teammate-base` — the versioned definition that carries the
observer pairing and the budget rules. A different agent type is fine when the
role has its own definition (`security-reviewer`, say); the teammate then follows
that one instead.

**4. Populate the shared task list**, with dependencies where a task genuinely
blocks another. Teammates claim, complete, and self-assign the next unblocked
task. Claiming is file-locked, so two teammates cannot take the same one.

**5. Stay out of the work.** The failure mode here is the lead deciding it is
faster to do the task itself while teammates are still working. Wait, then
synthesize. If a teammate stalls, message it; if it is stuck, spawn a replacement
rather than absorbing its task.

**6. Shut down and report.** Ask teammates to shut down by name when the work is
done. Team directories clean themselves up when the session ends; the task list
persists for a resumed session.

## Chaining skills

Chaining happens **inside** a teammate: it invokes the skill itself, by name,
with the Skill tool. That is the only mechanism, and it has one trap worth
knowing.

**`skills:` frontmatter does not preload into a teammate.** For an ordinary
subagent it injects the full skill content at startup. For a teammate it is
ignored — the teammate loads project and user skills the normal way and must
invoke them. A role definition that lists `skills:` and a spawn prompt that never
names one produces a teammate that runs no skill at all, with nothing in the
output saying so. **Name the skill in the spawn prompt.**

Sequencing a chain across teammates is a task-list job, not a skill feature: give
the dependent task a dependency on the one that must finish first. The harness
unblocks it when the earlier task completes.

The lead runs the tail of the chain — the step that needs everyone's output.
`/logbook:entry` after the work lands is the usual one; a teammate cannot write it
because no teammate saw the whole thing.

## Observers

An observer is a background agent paired to a working agent. After each of that
agent's turns it receives a read-only activity digest and stays silent unless it
has something worth the interruption, which it delivers through `ObserverReport`.
It never participates in the task and it has no `SendMessage`.

Observers are **not** spawned from here. They are declared in the observed
agent's own definition:

| Field | Meaning |
| --- | --- |
| `observer: <agentType>` | Agent type auto-spawned as a background observer whenever this agent runs |
| `observerMessage: <text>` | Extra postamble appended to each digest, after the harness's own |
| `observeSubagents: <bool>` | Whether subagents this agent spawns inherit the observer. Default **true** |

Two are versioned in these dotfiles: **`scope-guard`** (work that stopped being
the thing that was asked for) and **`regression-watch`** (changes likely to break
what works). `teammate-base` pairs with `scope-guard` and sets
`observeSubagents: false`, deliberately — inherited observers multiply down the
spawn chain and the budget above is why. For a risky refactor, spawn the
teammates with a role whose `observer:` is `regression-watch` instead.

Two hard limits: an observer never gets its own observer (no chaining), and
observer fan-out stops at depth 2, hardcoded.

**These three fields are undocumented** — they exist in the CLI binary and appear
on no docs page. Expect them to change or vanish with no deprecation note, and
verify against the binary rather than the docs when something stops working.

## When NOT to use a team

- **Sequential work.** Each step needs the last one's output; teammates just wait.
- **One file, or files that interleave.** Overwrites, not merges.
- **A task a subagent already handles.** A subagent that reports back is cheaper
  and simpler. Teams earn their cost when teammates need to *disagree*.
- **Small tasks.** Coordination overhead exceeds the work.
- **`-p` / non-interactive.** It silently is not a team.

## Failure modes worth recognizing

- **Teammates that never appear.** In-process teammates live in the agent panel
  below the prompt. An idle row hides after 30s and comes back on the next turn —
  hidden is not stopped.
- **A task stuck in progress.** Teammates sometimes finish work without marking
  the task done, which blocks everything depending on it. Check the work, then
  nudge the teammate or fix the status.
- **Permission prompts pile up on the lead.** Every teammate's prompt surfaces in
  the lead session. Pre-approve the obvious ones before spawning, not during.
- **Teams that form when nobody asked.** While agent teams are on, *any* subagent
  the model names launches as a teammate. If plain subagents are wanted, they must
  be spawned unnamed.
