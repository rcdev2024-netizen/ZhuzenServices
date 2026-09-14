# Vercel environment variables

Add these variables in the Vercel project settings for **Development, Preview, and Production** as appropriate:

## Vercel project settings

Because this repository is a workspace, configure the Vercel project with:

- **Root Directory:** repository root (`.`), not `artifacts/api-server`
- **Framework Preset:** Other
- **Build Command:** leave the Vercel default, or use `python -m compileall -q backend api`
- **Output Directory:** leave empty
- **Install Command:** leave the default

The root directory is important. The deployable Python function is
`api/index.py`, and the Vercel configuration is `vercel.json`, both at the
repository root. If Vercel is pointed at `artifacts/api-server`, it will run
that package's workspace build and then incorrectly look for a static `public`
directory.

| Variable | Required | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | Yes | The project URL, for example `https://your-project.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Server-only Supabase key used by FastAPI to access the tables. Never expose this to frontend code. |
| `JWT_SECRET` | Yes | Long random secret used to sign access and refresh tokens. Use a different value per environment. |
| `APP_ENV` | Yes | Use `production` on the production Vercel environment. |
| `CORS_ALLOW_ALL` | Optional | Defaults to `true`, allowing every browser origin. Set to `false` to enforce `CORS_ORIGINS`. |
| `CORS_ORIGINS` | Used when `CORS_ALLOW_ALL=false` | Comma-separated frontend origins, such as `https://app.example.com`. |
| `DEBUG` | Recommended | `false` in production. When enabled outside production, password reset responses include a development token. |
| `ACCESS_TOKEN_MINUTES` | Optional | Access-token lifetime, default `30`. |
| `REFRESH_TOKEN_DAYS` | Optional | Refresh-token lifetime, default `30`. |
| `PASSWORD_RESET_MINUTES` | Optional | Password reset-token lifetime, default `30`. |

`SUPABASE_ANON_KEY` is optional for this backend because server requests use
`SUPABASE_SERVICE_ROLE_KEY`. Set it only if a future feature needs to create
Supabase client configuration for a public consumer.

## Setup order

1. Create a Supabase project.
2. Run `supabase/migrations/001_initial_schema.sql`, then `supabase/migrations/002_domain_tables.sql` in the Supabase SQL Editor.
3. Add the environment variables above to Vercel.
4. Deploy from the repository root. Vercel will use `api/index.py` through `vercel.json`.
5. Verify `/api/healthz`, then create the first account with `POST /api/auth/register`.

## Fixing the current browser CORS error

No environment-variable change is required for the allow-all behavior after
deploying this code because `CORS_ALLOW_ALL` defaults to `true`. If the Vercel
project already has `CORS_ALLOW_ALL` set to `false`, either delete that
variable or set it to `true` in the Production environment, then redeploy.

If you prefer to restrict the API later, set:

```text
CORS_ALLOW_ALL=false
CORS_ORIGINS=https://servoces-ops-chi.vercel.app
```

The value must be the exact frontend origin: scheme plus hostname, without a
trailing slash or a path.