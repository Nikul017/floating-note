---
name: session_export
description: Summarizes the current engineering session, updates feature maps, and commits all changes to git with a detailed message.
---

# Session Export Skill (Upgraded)

This skill defines the workflow for documenting coding session changes, updating system architecture maps, exporting a session log, and committing changes to Git with a detailed commit message.

## Activation Trigger

This skill is invoked whenever the user triggers `/save-session`, commands a save, or when wrapping up a feature development iteration.

---

## Workflow Steps

### 1. Analyze Changes & Sync Maps
- Examine git status or diffs using terminal tools or log histories.
- If database models, state providers, or native channel routes were added or changed:
  - Locate and update the relevant feature maps under `.agents/maps/` (e.g. `notes_map.md`, `bookmarks_map.md`, `dependencies.md`).
  - Update `.agents/architecture/system_map.md` if high-level flows or tech stack changed.

### 2. Synthesize Work
- Summarize accomplishments, architectural decisions, and unresolved tasks.
- Create a new Markdown file inside `.agents/sessions/` named:
  `YYYY-MM-DD_<short-feature-slug>.md`

### 3. Stage and Commit Changes
- Stage all files in Git:
  `git add .`
- Create a detailed commit message containing the session accomplishments and files modified.
- Commit the changes:
  `git commit -m "[Detailed Commit Message]"`
