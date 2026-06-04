---
name: pr
description: Use whenever the user wants to open a pull request, draft a PR description, or says anything like "open a PR", "write a PR description", "create a pull request", "draft the PR body", or "/pr". Analyzes the diff between the current branch and its base, detects the repository's PR template if present, and produces a reviewer-oriented title plus body that explains *what the change does and why*—not a commit-by-commit log. Includes review instructions that guide a human through the change in the order they should read it. Defaults to emitting the text for the user to paste; offers to invoke `gh pr create` if the user wants. Trigger on any phrasing that involves describing or opening a PR, even if the user doesn't say "skill".
---

# pr

A pull request description is for humans who are about to spend their attention on your change. Their attention is the scarce resource. The PR body's job is to make that attention land where it matters: what the change does, why it exists, and where to start reading.

Two things this skill explicitly does **not** do:

- **Do not list commits.** Reviewers see the commit log in GitHub already. Repeating it in the body wastes screen space and tempts you to describe mechanics instead of intent. Trust the commits to tell their own story; the PR body operates at a level above them.
- **Do not mention tooling, or narrate how you verified the change.** No "written with Claude", no "ran the migration", no "ran the tests and they pass", no test-output dumps, no AI footers. *How* you checked the work is process; the PR body is about the change itself, and CI already reports test status. The single exception is when the repo explicitly asks for it: a `Testing` (or `Verification`, `QA`, etc.) heading in the PR template, or a documented expectation in `CONTRIBUTING.md` / a `.github/` policy. Then fill exactly that section with exactly what it asks for, and nothing more—don't volunteer verification notes the repo never requested. Reviewer-facing *manual test steps* ("to reproduce: open two tabs and POST within the same second") are different and welcome; reporting what you personally ran is not.

## Work order

1. **Find the base.** Determine what the PR is *against*. Try, in order:
   - `gh pr view --json baseRefName -q .baseRefName` (if a PR already exists).
   - `git config --get branch.$(git rev-parse --abbrev-ref HEAD).merge` (tracking branch).
   - `git symbolic-ref refs/remotes/origin/HEAD` → typically `main` or `master`.
   - Ask the user if none of the above resolve cleanly.
2. **Read the change.**
   - `git log --no-merges --oneline <base>..HEAD` — the commit narrative at a glance.
   - `git log --no-merges <base>..HEAD` — the **full commit messages, bodies and all**. This is the highest-value source and the one most easily skipped: a careful author has already written the *why*, the before→after, the findings, and the issue links into the commit bodies. Mine them for the Summary, Why-now, and Risks sections rather than reverse-engineering intent from the diff. When a body explains a non-obvious decision, the PR is where that reasoning earns a wider audience—lift it up, don't make the reviewer go spelunking through `git log` to find it.
   - `git diff --stat <base>..HEAD` — what's touched, at what scale.
   - `git diff <base>..HEAD` — the actual change. Skim, don't read every line; focus on entry points and anything marked as breaking.
3. **Detect the PR template.** Look for `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `docs/PULL_REQUEST_TEMPLATE.md`. If present, structure the body to match its headings. Do not invent sections it doesn't have.
4. **Find the issue link.** Same sources as the `commit` skill: branch name, commit footers, code annotations, conversation context. See `references/review-guidance.md` for how to phrase `Closes #N` etc.
5. **Draft the title.** One line, ≤72 chars, present tense, mirrors the repo's PR title style (often Conventional Commits–style, even when commit subjects aren't).
6. **Draft the body.** See `references/body-structure.md`. Lead with what changed and why; close with review instructions.
7. **Decide on output.**
   - **Default:** emit the title + body as text, ready to paste.
   - **If the user asks to open it:** run `gh pr create --title "…" --body "$(cat <<'EOF' … EOF)"`. Push the branch first if not already pushed. Confirm before pushing.

## What goes in the body

The body answers, in roughly this order:

1. **Summary.** Two or three sentences. What the PR does, at the level of "a stranger reading the repo for the first time" would understand. Not "I refactored the foo to bar"—rather "Adds an explicit booking step before message exchange, so two clients can't claim the same therapist slot."
2. **Why now.** One or two sentences on the motivation. The trigger: a user-reported bug, a compliance requirement, a perf regression, a new product surface. Link the issue here.
3. **Key changes.** A short bulleted list of the *load-bearing* changes, not every file. Three to seven bullets is the sweet spot. A bullet should be a noun phrase a reviewer can use as a heading when navigating the diff.
4. **Risks / notes.** Anything a reviewer should weigh: behavioral changes for existing callers, backward-compatibility concerns, performance implications, feature flags, migration sequencing. Skip the section if nothing here applies.
5. **Review instructions.** The most underused and highest-leverage section. A short prose paragraph that tells the reviewer *how to read the change*: where to start, what to inspect next, and what to be careful about. See `references/review-guidance.md`.

Optional sections (only if the template asks, or the change genuinely needs them): screenshots, deployment notes, follow-ups.

## What stays out

- No commit list (`* abc1234 Add foo`). The "Files changed" tab has this.
- No tooling or verification chatter: no test output, no "I ran `cargo test`", no "ran the migration locally", no "Claude wrote this", no co-authored-by lines unless the user has explicitly asked. Exception: a `Testing`/`Verification` section the PR template or `CONTRIBUTING.md` explicitly requires—fill that, and only that.
- No apologies or hedges ("sorry, this is a big one"). State scale neutrally if you need to ("Touches 14 files; most are mechanical call-site updates for the new signature.").
- No forward-looking promises ("will follow up with cleanup"). Either file an issue and link to it, or omit.
- No re-statement of every diff hunk in prose. Trust the diff.

## Title

A PR title is read in lists—issue search, merged-PR digests, release notes. It must stand alone.

Mirror the project's existing PR titles (`gh pr list --state merged --limit 20 --json title -q '.[].title'`). Common shapes:

- `feat(api): add session booking endpoint` (Conventional Commits in title).
- `Add session booking endpoint` (plain imperative, the simplest good default).
- `MED-481: Add session booking endpoint` (ticket-prefixed).

Don't pack the body into the title. ≤72 chars; the issue ID goes in the body if it doesn't fit.

## Opening the PR

If the user wants you to open it:

```bash
git push -u origin HEAD                  # confirm with user first
gh pr create \
  --base <base-branch> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body>
EOF
)"
```

If a PR already exists on this branch, prefer `gh pr edit` over creating a new one. If the user wants to update an open PR's description, `gh pr edit --body …` replaces it entirely—make sure to preserve sections they wrote.

## Reference files

- `references/body-structure.md` — section-by-section templates with worked examples.
- `references/review-guidance.md` — how to write the "review instructions" section.
- `references/pr-templates.md` — handling repo `pull_request_template.md` files.
