# Knowledge Base — bus-reservation

This is the source of truth for what's going on in this project. It exists so decisions get
grounded in what was actually decided here, not in general training data.

- `INDEX.md` — always read this first to see what notes exist.
- `PLAN.md` — the living top-level plan: one-sentence scope, primary flow, entity model, MVP
  scope. Changes shape as the project evolves; churny detail lives in `decisions/` instead.
- One decision/fact per file under `decisions/` and `reference/`. Frontmatter has `title`,
  `tags`, `date`. `[[slug]]` links point to other files by their `title` frontmatter value.

When asked to save something here: check `INDEX.md` for an existing note to update before
creating a new one. Always add new notes to `INDEX.md` in the same sitting.

When answering a question about this project:
- Read `INDEX.md`, then open only the notes that look relevant.
- Answer using only what's in those notes. If this KOS has nothing on the question, say
  "not in the KOS" explicitly — do not fill the gap from general knowledge.
- End the answer with a "Sources:" line listing the file paths actually read. No sources means
  the answer wasn't grounded here, no matter how specific it sounds.
