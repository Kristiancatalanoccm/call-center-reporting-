# /start — Reporting Dashboard Setup

You are setting up a call center reporting dashboard from scratch. Work through every step in order, reporting progress at each one. Do not stop unless a step fails — keep going.

---

## Step 1 — Read and validate .env.local

Read `.env.local` in the current directory.

Check that ALL of the following have real values — not placeholder text like `your-key-here`, `xxxx`, or empty:

| Variable | Where to find it |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | supabase.com → project → Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Same page, long JWT starting with `eyJ` |
| `SUPABASE_ACCESS_TOKEN` | supabase.com → Account → Access Tokens → New token (starts with `sbp_`) |
| `ADMIN_WEBHOOK_SECRET` | Make up any strong password |
| `MAKE_API_KEY` | make.com → Profile → API → Personal access tokens |
| `MAKE_TEAM_ID` | Numeric ID in your Make team URL |
| `MAKE_REGION` | `eu2` or `us1` depending on your Make account region |
| `RAILWAY_TOKEN` | railway.app → Account Settings → Tokens → New token |

If any are missing or still placeholder, **stop and list exactly which ones** need filling in. Do not continue until the user confirms they're done.

Extract and remember:
- `SUPABASE_PROJECT_REF` = subdomain from `NEXT_PUBLIC_SUPABASE_URL` (between `https://` and `.supabase.co`)
- `SUPABASE_ACCESS_TOKEN`, `SUPABASE_SERVICE_ROLE_KEY`
- `MAKE_API_KEY`, `MAKE_TEAM_ID`, `MAKE_REGION`
- `RAILWAY_TOKEN`
- `ADMIN_WEBHOOK_SECRET`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

## Step 2 — Apply Supabase schema

Read `supabase/schema.sql` and execute it:

```bash
curl -s -X POST "https://api.supabase.com/v1/projects/{SUPABASE_PROJECT_REF}/database/query" \
  -H "Authorization: Bearer {SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(node -e "process.stdout.write(JSON.stringify(require('fs').readFileSync('supabase/schema.sql','utf8')))")}"
```

If the response contains an error key, report it and stop. If it returns `[]` or row data, continue.

---

## Step 3 — Update Supabase max rows

Supabase defaults to 1000 rows max which breaks the dashboard. Update to 100,000:

```bash
curl -s -X PATCH "https://api.supabase.com/v1/projects/{SUPABASE_PROJECT_REF}/postgrest" \
  -H "Authorization: Bearer {SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"max_rows": 100000}'
```

Confirm `max_rows` is `100000` in the response before continuing.

---

## Step 4 — Import Make blueprints

### 4a — Create a Make folder

```bash
curl -s -X POST "https://{MAKE_REGION}.make.com/api/v2/scenarios-folders" \
  -H "Authorization: Token {MAKE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Reporting Dashboard\", \"teamId\": {MAKE_TEAM_ID}}"
```

Extract and remember the folder `id` as `MAKE_FOLDER_ID`.

### 4b — Import each blueprint

For each of these files in `make-blueprints/` (skip any not listed):

- `ccm-new-lead.blueprint.json`
- `ccm-appt-booked.blueprint.json`
- `ccm-show.blueprint.json`
- `ccm-no-show.blueprint.json`
- `ccm-dial.blueprint.json`
- `ccm-callback.blueprint.json`
- `ccm-onboarding.blueprint.json`

For each one:
1. Read the JSON file into memory
2. If `blueprint.flow[0].parameters.hook` exists, set it to `null` (Make auto-creates a fresh webhook on first open)
3. Serialize the entire blueprint object to a JSON string
4. POST to create the scenario:

```bash
curl -s -X POST "https://{MAKE_REGION}.make.com/api/v2/scenarios" \
  -H "Authorization: Token {MAKE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"teamId\": {MAKE_TEAM_ID}, \"folderId\": {MAKE_FOLDER_ID}, \"blueprint\": \"{ESCAPED_BLUEPRINT_STRING}\", \"scheduling\": \"{\\\"type\\\":\\\"indefinitely\\\",\\\"interval\\\":900}\"}"
```

Note: `blueprint` must be a JSON-encoded **string** (the whole object serialized), not an object literal.

Report after each: ✓ `ccm-new-lead` imported (ID: 12345)

If one fails, note the error and continue with the rest.

---

## Step 5 — Deploy to Railway

### 5a — Check Railway CLI

Check if the Railway CLI is installed:

```bash
railway --version 2>/dev/null || echo "NOT_INSTALLED"
```

If not installed:

```bash
npm install -g @railway/cli
```

### 5b — Create Railway project

```bash
curl -s -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer {RAILWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"mutation { projectCreate(input: { name: \\\"Call Center Reporting\\\" }) { id environments { edges { node { id name } } } } }\"}"
```

Extract:
- `RAILWAY_PROJECT_ID` = the project `id`
- `RAILWAY_ENV_ID` = the `id` from the first environment node (the default production environment)

### 5c — Create a service in the project

```bash
curl -s -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer {RAILWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"mutation { serviceCreate(input: { projectId: \\\"{RAILWAY_PROJECT_ID}\\\", name: \\\"dashboard\\\" }) { id } }\"}"
```

Extract `RAILWAY_SERVICE_ID` from the response.

### 5d — Set all environment variables on the service

Build a variables object containing ALL of the following (use the real values from .env.local):

```
NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
SUPABASE_ACCESS_TOKEN, ADMIN_WEBHOOK_SECRET, MAKE_API_KEY, MAKE_TEAM_ID, MAKE_REGION,
RAILWAY_TOKEN, RAILWAY_PROJECT_ID (use the ID you just created)
```

Then run:

```bash
curl -s -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer {RAILWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"mutation { variableCollectionUpsert(input: { projectId: \\\"{RAILWAY_PROJECT_ID}\\\", serviceId: \\\"{RAILWAY_SERVICE_ID}\\\", environmentId: \\\"{RAILWAY_ENV_ID}\\\", variables: {ESCAPED_VARS_JSON} }) }\"}"
```

Where `ESCAPED_VARS_JSON` is a GraphQL-safe key:value map of all the variables.

### 5e — Deploy

```bash
RAILWAY_TOKEN={RAILWAY_TOKEN} railway up \
  --project {RAILWAY_PROJECT_ID} \
  --service {RAILWAY_SERVICE_ID} \
  --environment production \
  --ci \
  --detach
```

This uploads the current directory and triggers a build. It takes 2-3 minutes.

### 5f — Get the live URL

After deploying, fetch the service domain:

```bash
curl -s -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer {RAILWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"{ project(id: \\\"{RAILWAY_PROJECT_ID}\\\") { services { edges { node { name domains { edges { node { domain } } } } } } } }\"}"
```

Extract the domain and report it as the dashboard URL.

---

## Step 6 — Done! Print summary and next steps

```
✓ Supabase schema applied (9 tables created)
✓ Supabase max rows updated to 100,000
✓ Make blueprints imported:
    ✓ ccm-new-lead       (ID: ...)
    ✓ ccm-appt-booked    (ID: ...)
    ✓ ccm-show           (ID: ...)
    ✓ ccm-no-show        (ID: ...)
    ✓ ccm-dial           (ID: ...)
    ✓ ccm-callback       (ID: ...)
    ✓ ccm-onboarding     (ID: ...)
✓ Railway project created and deployed
    Dashboard URL: https://YOUR-APP.up.railway.app

── 3 manual steps remaining ──────────────────────────────

1. ACTIVATE MAKE SCENARIOS + COPY WEBHOOK URLS
   - Open Make → "Reporting Dashboard" folder
   - Open each scenario → click the webhook module → copy the URL
   - Turn each scenario ON (toggle in the bottom left)

2. SET UP GHL WORKFLOWS (one per event):
   - New Lead               → ccm-new-lead webhook URL
   - Appointment Booked     → ccm-appt-booked webhook URL
   - Appointment Showed     → ccm-show webhook URL
   - Appointment No-Showed  → ccm-no-show webhook URL
   - Call Ended (outbound)  → ccm-dial webhook URL
   - Callback Booked        → ccm-callback webhook URL

3. LOG IN + ADD YOUR FIRST CLIENT
   - Go to your dashboard URL above
   - Log in (create your account via Supabase → Authentication → Users → Invite)
   - Settings → add a client (name must match what Make sends as client_name)
   - Trigger a test GHL event to confirm data flows through
```
