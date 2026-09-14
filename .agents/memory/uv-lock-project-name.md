---
name: Python lockfile project name
description: The uv lockfile must be regenerated whenever the top-level Python project name changes.
---

When `pyproject.toml` changes the `[project].name`, regenerate `uv.lock` before Vercel runs its frozen sync.

**Why:** Vercel uses `uv sync --frozen`; a stale lockfile fails before the Python function is built.

**How to apply:** Run `uv lock`, then verify with `uv sync --active --no-dev --link-mode hardlink --frozen --no-editable`.