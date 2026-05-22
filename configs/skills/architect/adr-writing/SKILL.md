---
name: adr-writing
description: MADR format, decision log best practices, superseding decisions
---

# ADR Writing (Architecture Decision Records)

## What is an ADR?

An ADR is a short document capturing a significant architectural decision: the context, the options considered, the decision made, and the consequences. It is committed to the repo alongside the code it governs.

**Why bother?** Future you — and your teammates — need to know *why* the system is the way it is, not just what it is. ADRs prevent re-litigating the same decisions and make onboarding dramatically faster.

## MADR Format (Markdown Architectural Decision Records)

Use this template. Keep it concise — an ADR is not a design doc. It should be readable in under 5 minutes.

```markdown
# ADR-[NUMBER]: [Short Title]

**Date:** YYYY-MM-DD
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-XXX]
**Deciders:** [Names or team]

---

## Context and Problem Statement

[1–3 sentences. What is the situation and why does a decision need to be made?]

## Decision Drivers

- [Constraint or quality attribute that matters most]
- [e.g., "team has no Kubernetes experience"]
- [e.g., "must handle 50K req/s at peak"]

## Options Considered

### Option 1: [Name]
[Brief description]

**Pros:**
- ...

**Cons:**
- ...

### Option 2: [Name]
...

### Option 3: [Name]
...

## Decision

**Chosen option: [Name]**

[2–4 sentences explaining why this option was chosen over the others, tied directly to the decision drivers above.]

## Consequences

**Positive:**
- [What gets better]

**Negative / Trade-offs:**
- [What we give up or take on]

**Risks:**
- [What could invalidate this decision and trigger a revisit]

## Links

- [Related ADR, RFC, or doc]
- [Benchmark or article that informed the decision]
```

## File Naming and Storage

Store ADRs in: `docs/architecture/decisions/`

File naming: `ADR-0001-short-title.md`, `ADR-0002-short-title.md`, ...

Zero-pad to 4 digits so they sort correctly in any file explorer.

## Status Lifecycle

```
Proposed → Accepted → Deprecated
                   ↘ Superseded by ADR-XXXX
```

- **Proposed** — Draft, under discussion
- **Accepted** — Decision made, in effect
- **Deprecated** — No longer relevant (e.g., the component was removed)
- **Superseded** — A newer ADR overrides this one. Always link to the new ADR and keep the old one in place — never delete ADRs.

## What Makes a Good ADR

| ✅ Do | ❌ Don't |
|------|---------|
| Capture the *why*, not just the *what* | Document obvious decisions that needed no deliberation |
| List options you actually considered | List strawman options you never seriously evaluated |
| Record the constraints that drove the decision | Write a general design doc — ADRs are decisions, not tutorials |
| Link to supporting evidence (benchmarks, docs) | Leave status as "Proposed" forever |
| Update status when a decision is superseded | Delete or rewrite old ADRs |

## Threshold: What Deserves an ADR?

Write an ADR when the decision:

- Is **hard to reverse** (database choice, API protocol, auth system)
- Affects **more than one team or service**
- Has **significant tradeoffs** that future engineers should understand
- Was **debated** — if you argued about it, document it
- Involves **external vendors or paid services**

Skip an ADR for:
- Library version bumps
- Refactors within a single module
- Styling or formatting choices

## ADR Index

Maintain an `INDEX.md` in `docs/architecture/decisions/`:

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-0001](ADR-0001-use-postgresql.md) | Use PostgreSQL as primary database | Accepted | 2024-01-15 |
| [ADR-0002](ADR-0002-event-driven-notifications.md) | Use event-driven architecture for notifications | Accepted | 2024-02-03 |
```

## Tooling (Optional)

- **[adr-tools](https://github.com/npryce/adr-tools)** — CLI to scaffold new ADRs: `adr new "Use PostgreSQL as primary database"`
- **[Log4brains](https://github.com/thomvaill/log4brains)** — Generates a static web UI from your ADR folder
- **[pyadr](https://github.com/opinionated-digital-center/pyadr)** — Python CLI with MADR support
