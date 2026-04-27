# ReDefine You — Workspace Map

## What This Is

A workspace for ReDefine You, a med spa running an in-house call center.
Setters dial leads and book appointments for treatments/consultations — same
operational model as a marketing agency call center, just internal.

This file (CLAUDE.md) is the map. Always loaded. Never delete it.

---

## Business Context

- **Business type:** Med spa (aesthetics, wellness treatments)
- **Call center model:** In-house setters dialling leads, booking consultations
- **Reporting stack:** GHL → Make.com → Railway (Next.js) → Supabase → Dashboard
- **"Clients" in the system:** Service lines or lead sources (e.g. "Botox Leads", "Weight Loss Leads") — not external agencies

---

## Folder Structure

```
redefine-you/
├── CLAUDE.md                        ← You are here (always loaded map)
├── CONTEXT.md                       ← Task router
│
├── reporting/                       ← Call center reporting dashboard
│   ├── CONTEXT.md                   ← Reporting workspace instructions
│   ├── make-blueprints/             ← Make.com scenario blueprints
│   └── tracking-app/                ← Next.js dashboard + webhook receiver
│
└── (future folders for other medspa work)
```

---

## Quick Navigation

| Want to... | Go here |
|------------|---------|
| **Work on the dashboard** | `reporting/CONTEXT.md` |
| **Update webhook schemas** | `reporting/CONTEXT.md` |
| **Add a new metric** | `reporting/tracking-app/src/` |
| **Update Make blueprints** | `reporting/make-blueprints/` |

---

## Naming Conventions

| Content Type | Pattern |
|-------------|---------|
| Webhook Payloads | `[system]-webhook.json` |
| Components | `[ComponentName].tsx` |
| API Routes | `src/app/api/[name]/route.ts` |

---

## Token Management

**Each workspace is siloed.** Only load what's relevant to the task.
If working in `reporting/`, only load that directory.
