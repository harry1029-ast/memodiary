# Issue tracker: Local Markdown

Specs and tickets for this repo live as markdown files. Specs are committed; tickets are local working files.

## Conventions

- **Specs** are committed at `docs/specs/NNNN-<slug>.md`, numbered by incrementing the highest existing spec number.
  - Frontmatter: `id: SPEC-NNNN`, `title`, `status`, `created_at`, and optionally `adr: ADR-NNNN`.
  - The spec's triage state is its frontmatter `status` (see `triage-labels.md`).
- **Tickets** live at `.scratch/<slug>/issues/<NN>-<slug>.md`, one file per ticket, numbered from `01`, never a single combined tickets file. `<slug>` is the spec's slug without its number (e.g. SPEC-010 `0010-staging-handscroll-and-text-anchored-mounting` → `.scratch/staging-handscroll-and-text-anchored-mounting/`).
  - Each ticket carries a `**Blocked by:**` line (`None` or ticket numbers) and a `**Status:**` line near the top.
- An optional working draft may live at `.scratch/<slug>/spec.md`; `docs/specs/` is always the canonical copy.
- Comments and conversation history append to the bottom of the file under a `## Comments` heading.
- `.scratch/` is gitignored: tickets are local to this machine and are not shared through git.

## When a skill says "publish to the issue tracker"

- A **spec** goes to `docs/specs/NNNN-<slug>.md`.
- A **ticket** goes to `.scratch/<slug>/issues/<NN>-<slug>.md` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path, the spec id (e.g. SPEC-010), or the ticket number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
