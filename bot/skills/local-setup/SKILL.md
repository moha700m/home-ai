---
name: local-setup
description: How to run this agent locally on the user's PC and pick a model size from pc_specs tier. Use when the user asks to install, run, or tune the local agent.
---

# Local setup

## Run the playground

```bash
npm install
npx @cursor/bdk serve --dir . --mode single --dev --port 3847
```

Open `http://127.0.0.1:3847/playground`.

Model turns need a Cursor credential:

```bash
npx @cursor/bdk login
# or export CURSOR_API_KEY=...
```

## Match models to tier from `pc_specs`

| Tier | RAM guide | Local models |
| --- | --- | --- |
| light | under ~14 GiB | 1B–3B instruct |
| medium | ~14–31 GiB | 7B–14B quantized |
| strong | 32 GiB+ or discrete GPU | 14B–70B quantized (GPU preferred) |

Prefer one runnable suggestion over a long catalog.
