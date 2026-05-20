# AI Context Loading Rules

> [!IMPORTANT]
> To ensure codebase continuity, prevent architectural regression, and maintain visual styles, the AI assistant MUST follow these steps before proposing or implementing any codebase modifications.

## Rules of Engagement

### 1. Read Architecture Docs
- Always begin by viewing `.agents/architecture/system_map.md` to refresh understanding of the system's pattern (feature-first structure, Riverpod state boundaries, local SQLite, and native platform integrations).

### 2. Read Feature Maps
- Review the specific feature map under `.agents/maps/` matching the code area you are changing (e.g., `notes_map.md` for overlay updates, `dashboard_map.md` for screen filter updates, `dependencies.md` to see interactions).

### 3. Read Recent Session Summaries
- Look at the latest session files in `.agents/sessions/` to review what was accomplished last, what decisions were made, and which next steps are active.

### 4. Review Platform/Design Guidelines
- Refer to agent rules in `.agents/AGENTS.md` (like `Flutter Architect` or `UI & UX Designer`) to align on code styling, spacing, colors, and motion rules.

### 5. Handle Vague Requests (Planning Skill)
- If the user's prompt is brief, vague, or structurally complex, you MUST activate the `planning` skill first. Generate a structured proposal showing interpreted goals, target files to change, and specific clarifying questions, and halt for user feedback before coding.

### 6. Validate Before Writing Code
- Verify that your proposed edits do not duplicate existing providers, create sync feedback loops on method channels, or violate database schemas.
