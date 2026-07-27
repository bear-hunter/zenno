# Zenno — UI/UX Design Explorations

Five complete redesigns of Zenno (the infinite-canvas study app), each a distinct
visual + UX direction and **miles ahead of the current stock Material 3 look**.

Each is a self-contained, interactive HTML prototype (no build step, vanilla JS).
Click the nav to move between all six screens: **Library · Focus · Revision · Goals ·
Settings · Canvas Editor** (plus the active focus timer).

## Run them (all five at once, each on its own port)

```bash
python3 UIUXdesign/serve.py
```

Then open:

| Port | Codename | Direction |
|------|----------|-----------|
| http://localhost:8001 | **Aurora**  | Premium glassmorphic dark — aurora mesh, frosted panels, luxe gold |
| http://localhost:8002 | **Atelier** | Warm light "study desk" — paper/ink, elegant serif, editorial |
| http://localhost:8003 | **Zen**     | Ultra-minimal calm — huge whitespace, focus-first, one quiet accent |
| http://localhost:8004 | **Bold**    | Neo-brutalist pop — thick borders, hard shadows, sticker tags |
| http://localhost:8005 | **Command** | Pro / dense — Linear/Raycast energy, ⌘K palette, keyboard-first |

(Each design also opens on its own — just open the `index.html` in any folder.)

## Folders

```
UIUXdesign/
  serve.py            # serves all five on ports 8001–8005
  01-aurora/index.html
  02-atelier/index.html
  03-zen/index.html
  04-bold/index.html
  05-command/index.html
```
