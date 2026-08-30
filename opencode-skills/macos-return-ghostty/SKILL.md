---
name: macos-return-ghostty
description: After using any macos-mcp tool (App, Click, Type, Scroll, Shortcut, Move, Snapshot, Shell with GUI apps, etc.), always return focus to the Ghostty terminal at the end of the turn. Use whenever the session involves macos-mcp desktop automation so the user knows the agent has finished operating the GUI.
---

# Return focus to Ghostty after macOS automation

Whenever this session uses ANY `macos-mcp_*` tool that touches the GUI
(`macos-mcp_App`, `macos-mcp_Click`, `macos-mcp_Type`, `macos-mcp_Move`,
`macos-mcp_Scroll`, `macos-mcp_Shortcut`, `macos-mcp_Snapshot`, `macos-mcp_Desktop`,
or `macos-mcp_Shell` commands that open/focus apps such as `open -a ...`),
the LAST action of the turn MUST bring focus back to the Ghostty terminal
running opencode, so the user immediately sees the agent has finished.

## How to return focus

Preferred (deterministic, no ambiguity):

```
macos-mcp_App with { "mode": "switch", "name": "Ghostty" }
```

Fallback if the switch call fails:

```
macos-mcp_Shell with { "mode": "osascript", "command": "tell application \"Ghostty\" to activate" }
```

Do NOT rely on `command+tab` via `macos-mcp_Shortcut` — the app order depends
on recency and is not deterministic.

## Rules

1. Perform all requested GUI operations first (open apps, click, type, verify results).
2. Only AFTER the last GUI operation completes (including any verification snapshot),
   switch focus back to Ghostty using the preferred method above.
3. Do not switch back in the middle of a multi-step GUI workflow — only when the
   turn's GUI work is done and the next step is waiting on the user or is pure
   terminal/local work.
4. If the turn only reads state (e.g., a Snapshot that required no GUI change) and
   nothing on screen changed focus away from Ghostty, switching back is still
   harmless — but skip it if Ghostty is already the focused window to avoid noise.
5. After switching back, report the result of the GUI work to the user in the reply.
