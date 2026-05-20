---
name: planning
description: Triggers automatically on vague, complex, or ambiguous user requests. Instructs the agent to analyze, structure a plan, ask clarifying questions, and obtain user approval before writing code.
---

# Planning & Clarification Skill

Use this skill when a user request is vague, brief, or architectural in nature (e.g., "add sync", "improve layout", "fix overlays"). It prevents the agent from making assumptions, writing incorrect code, or creating design inconsistencies.

---

## 1. Request Analysis (Deconstruction)
Before proposing or making any changes:
- Check if the request has unspecified requirements, stack preferences, or design styles.
- Read `.agents/architecture/system_map.md` and feature maps under `.agents/maps/` to locate relevant files, databases, and dependencies.

---

## 2. Generate a Structured Clarification Plan
Present the user with an initial analysis outlining:
1. **Interpretation**: What you understand the user wants to accomplish.
2. **Affected Components**: Lists of providers, views, services, or models that will need edits.
3. **Implicit Challenges**: Potential edge cases, security implications, or sync loops.

---

## 3. Formulate Clarification Questions
List specific, concise questions to resolve ambiguities. Group questions into:
- **Design & UX**: Specific spacing, animations, density, or theme variables.
- **Architecture**: Choice of providers, local storage transactions, or method channel boundaries.
- **Behavioral/Edge Cases**: Network failures, empty lists, or invalid permission handling.

---

## 4. Output Template for Vague Requests

Format your planning response exactly like this:

```md
# Proposal & Clarification: [Task Name]

## 1. What I Understand
[Explain your interpretation of the vague prompt in detail]

## 2. Proposed File Modifications
- [MODIFY] [filename](file:///path/to/file) - Reason
- [NEW] [filename](file:///path/to/file) - Reason

## 3. Clarifying Questions
> [!IMPORTANT]
> Please answer or select from the following options to help me refine the plan:
>
> 1. **[Question Title]**
>    - Option A: ...
>    - Option B: ...
> 2. **[Question Title]**
>    - Option A: ...
>    - Option B: ...
```

---

## 5. Halt for Approval
- **CRITICAL**: Do NOT generate, edit, or delete any source code files until the user explicitly responds to the questions and approves the proposed plan.
