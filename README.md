# Herdr orchestration skills, Hermes variant

A version of [`herdr-plan`](../herdr-plan/README.md) for driving the orchestration from Telegram. Hermes Agent listens to a Telegram bot and, with the [`hermes/herdr`](hermes/herdr/SKILL.md) skill, starts the Claude Code orchestrator in a Herdr pane, passes your messages to it as they are and forwards its questions and milestones back to you.

The step-by-step guide (architecture, installation, testing and open questions) is in [`herdr-telegram-hermes.html`](herdr-telegram-hermes.html).

| Folder | For whom | What it is |
|---|---|---|
| [`writing-herdr-plans-hermes/`](writing-herdr-plans-hermes/SKILL.md) | Claude Code | `writing-herdr-plans` with the plan's questions and summary sent over Telegram |
| [`executing-herdr-plans-hermes/`](executing-herdr-plans-hermes/SKILL.md) | Claude Code | `executing-herdr-plans` with the "Telegram channel" section and `scripts/notify-telegram.sh` |
| [`hermes/herdr/`](hermes/herdr/SKILL.md) | Hermes Agent | The bridge: `/herdr nuevo`, `ejecutar`, `status`, `ver`, `pendiente`, `parar` commands |
| [`setup/`](setup/) | The host | Herdr systemd unit, headless size and `~/.hermes/.env` variables |

## What changes compared to herdr-plan

Everything new is only activated by `HERDR_TG=1`, which Hermes sets when it launches the orchestrator. Without that variable, the two skills behave exactly like the originals.

- **Names:** the skills are called `writing-herdr-plans-hermes` and `executing-herdr-plans-hermes`, and their cross-references point to those names. This way they can coexist with the originals in `~/.claude/skills/`.
- **Descriptions:** they trigger when the run comes from Telegram (`HERDR_TG=1`, the `[telegram user=… msg=…]` prefix or a prompt that names the skill). The bridge always names the skill in the prompt.
- **`executing-herdr-plans-hermes/SKILL.md`:**
  - Overview: "Hermes variant" paragraph.
  - Preflight step 1: checks the channel variables and sends a first event.
  - Preflight step 8: `systemd-inhibit` on Linux in addition to `caffeinate` on macOS.
  - New "Telegram channel" section after "ClickUp events": how to ask (`Q-n`, `~/.cache/herdr-telegram/pending.md`), how to record answers as D-numbers, which events are sent and which are never sent.
  - Status and Resume: also answers over Telegram and forwards the open questions.
  - Hand-off to a relief orchestrator at 70% context, as in `herdr-plan`. With `HERDR_TG=1` the first orchestrator keeps the name `orch`, the relief pane gets the channel variables, and `~/.cache/herdr-telegram/orch` tells the bridge which orchestrator to prompt (`handoff orch-N` while one is taking over). The relief announces itself with an `event`.
  - Quick Reference and Red Flags: one new row and three new rows for Telegram, plus the hand-off rows.
- **`executing-herdr-plans-hermes/handoff-template.md`:** the one from `herdr-plan`, plus a Telegram line (last `Q-n`, open questions, failed sends, pointer).
- **`hermes/herdr/SKILL.md`:** the bridge prompts the agent named in `~/.cache/herdr-telegram/orch` instead of a fixed `orch`, and holds your messages while a hand-off is in progress.
- **`executing-herdr-plans-hermes/scripts/notify-telegram.sh`:** new. Signs the message with HMAC and sends it to the `herdr-events` route of the Hermes webhook.
- **`executing-herdr-plans-hermes/scratchpad-template.md`:** new "Telegram channel" section, plus the hand-off fields of `herdr-plan`.
- **`writing-herdr-plans-hermes/SKILL.md`:** "Telegram" paragraph at the top, the plan summary is also sent over Telegram and the approval question waits for the answer from there.
- **No content changes:** `make-package.sh`, `make-review-package.sh`, `fix-round-template.md`, `orchestration-section-template.md` and `animations-guidelines.md` (only the skill name changes in their references). The plan format is the same, so a plan written with one skill can be executed with the other.

## Requirements

Those of `herdr-plan`, plus:

- Hermes Agent with the Telegram gateway and the webhook platform;
- `jq`, `openssl` and `curl` on the host;
- a Claude Code status line that shows the context percentage (`ctx:N%`), which the orchestrator reads to hand off at 70%;
- a host that stays on, with `herdr server` running as a service.

## Installation

From the root of this folder:

```bash
ln -s "$PWD/writing-herdr-plans-hermes" ~/.claude/skills/writing-herdr-plans-hermes
ln -s "$PWD/executing-herdr-plans-hermes" ~/.claude/skills/executing-herdr-plans-hermes
ln -s "$PWD/hermes/herdr" ~/.hermes/skills/herdr
```

Then, in Telegram, `/reload-skills`. The rest of the setup (bot, webhook, services) is in steps 1 to 4 of the HTML.
