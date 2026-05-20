---
description: Summarizes the session, updates architecture maps, creates a session export, and commits changes to git with a detailed message.
---

1. Analyze recent git logs and diff changes to identify all files created, modified, or deleted.
2. Review feature maps inside `.agents/maps/` and architecture maps in `.agents/architecture/` and update them if logic, schemas, or data flows have changed during this session.
3. Determine today's date in `YYYY-MM-DD` format and ask the user for a short feature slug (e.g. `auth-setup`, `overlay-fixes`).
4. Write a detailed markdown file at `.agents/sessions/YYYY-MM-DD_<feature-slug>.md` documenting Accomplishments, Modified Files, Architectural Decisions, and Next Steps.
5. Stage all changes by running `git add .`.
6. Formulate a detailed commit message using the session summary (including accomplishments and files modified) and run `git commit -m "<message>"`.
