---
name: Python workflow working directory
description: The managed API workflow starts in the artifact directory, while the Python package lives at the repository root.
---

The API artifact's managed workflow executes its package script with `artifacts/api-server` as the working directory, so Python commands importing the root-level `backend` package must first change to `../..`.

**Why:** Without the directory change, Uvicorn starts but cannot import the application package.

**How to apply:** Keep the artifact package scripts rooted with `cd ../..` for local preview; Vercel imports the same package from the repository root through `api/index.py`.