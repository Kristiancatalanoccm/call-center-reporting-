# Reporting Workspace — ReDefine You

## What This Is

Call center reporting dashboard for ReDefine You's in-house setter team.
Tracks dials, pickups, conversations, appointments booked, shows, no-shows,
and cost metrics across all lead sources.

**Data pipeline:** GHL → Make.com → Railway (Next.js) → Supabase → Dashboard

## Status: Not Yet Set Up

The code is ready. The following steps need to be completed before going live.

---

## Setup Checklist

### 1. Create Supabase Project
- Go to supabase.com → New Project
- Copy: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- Run `tracking-app/supabase/schema.sql` in the SQL editor
- Run `node tracking-app/scripts/migrate.mjs` from the tracking-app directory

### 2. Deploy to Railway
- Push `tracking-app/` to a new GitHub repo
- Connect Railway → deploy from that repo
- Set all environment variables (see `.env.local.example`)
- Note the Railway URL (e.g. `redefine-you-production.up.railway.app`)

### 3. Import Make Blueprints
- In Make.com, create a folder called "ReDefine You Reporting"
- Import each blueprint from `make-blueprints/` (skip `ccm-agent-claim`)
- Add a webhook to each scenario, copy the URLs

### 4. Set Up GHL Workflows
- New Lead → New Lead webhook URL
- Appointment Booked → Appt Booked webhook URL
- Appointment Showed → Show webhook URL
- Appointment No Showed → No Show webhook URL
- Call Ended (outbound) → Dial webhook URL
- Callback Booked → Callback webhook URL

### 5. Add First "Client"
- Log into the dashboard → Settings → add first client
- For ReDefine You, clients = lead sources or service lines
  e.g. "Botox", "Weight Loss", "Skin Treatments"
- The `client_name` in Make must match exactly

### 6. Test End to End
- Trigger a real GHL event
- Check Supabase Table Editor → events table
- Confirm it appears on the dashboard

---

## Tech Stack

- **Framework:** Next.js App Router (TypeScript, Tailwind CSS v4)
- **Database:** Supabase (Postgres + Auth)
- **Hosting:** Railway
- **Automation:** Make.com
- **Source:** Forked from TFU AI reporting dashboard

---

## Supabase Schema

| Table | Purpose |
|-------|---------|
| `organizations` | Top-level org (ReDefine You = one org) |
| `profiles` | Admin users |
| `clients` | Lead sources / service lines |
| `events` | All GHL events (dials, leads, bookings, shows) |
| `ad_spend` | Daily Meta/Google spend by client |
| `agents` | Setters (name + phone) |
| `setter_availability` | Recurring availability windows |
| `client_calling_windows` | When each lead source is dialled |
| `watch_schedule` | Manager-assigned weekly watch shifts |
| `pd_schedule` | Generated power dialer schedule |

Event types: `dial`, `lead`, `appointment_booked`, `show`, `no_show`, `callback_booked`

---

## Environment Variables

All secrets go in `tracking-app/.env.local` (never committed).
See `tracking-app/.env.local.example` for the full list.

---

## File Navigation

| Task | File |
|------|------|
| Dashboard UI | `tracking-app/src/components/DashboardView.tsx` |
| Webhook ingestion | `tracking-app/src/app/api/webhooks/route.ts` |
| Metrics computation | `tracking-app/src/lib/metrics.ts` |
| Power Dialer Schedule | `tracking-app/src/components/SetterSchedule.tsx` |
| Agent Roster | `tracking-app/src/components/AgentRoster.tsx` |
| Client Roster | `tracking-app/src/components/ClientRoster.tsx` |
| Make blueprints | `make-blueprints/` |
