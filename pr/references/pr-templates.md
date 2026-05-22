# Handling repository PR templates

GitHub auto-fills a PR description from a template file when one is present. When the user opens a PR via the web UI, they see that template. Your draft should match it.

## Where templates live

Check in this order:

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md` (uppercase variant)
3. `.github/PULL_REQUEST_TEMPLATE/*.md` (per-type templates; folder, not file)
4. `docs/pull_request_template.md`
5. `pull_request_template.md` at repo root

If multiple templates exist in `.github/PULL_REQUEST_TEMPLATE/`, look at recent merged PRs to see which one the team actually uses:

```bash
gh pr list --state merged --limit 10 --json title,body -q '.[] | {title, body: (.body | .[0:200])}'
```

Pick the template that recent PRs follow.

## How to use a template

1. Read the template file end-to-end.
2. Identify its headings (typically `## Description`, `## Type of change`, `## Testing`, etc.).
3. Identify its checklists. Tick the items that genuinely apply; leave the rest unchecked—do not auto-tick "I added tests" if no tests were added.
4. Fill each section with content appropriate to the heading. Skip a section only if the template marks it optional and it truly doesn't apply.
5. Preserve HTML comments (`<!-- … -->`) the template uses as inline guidance—remove them only if their content has been addressed. Most teams expect them removed once filled.

## When the template conflicts with what's useful

Templates sometimes have sections that aren't a good fit for a specific PR (e.g. "Screenshots" for a backend-only change). In that case:

- If the template marks the section optional, omit it.
- If it doesn't, write `N/A` rather than removing the heading. The team's tooling may scan for the heading.
- Never invent new top-level headings the template doesn't have. Add subordinate content within existing headings instead.

## When there's no template

Use the structure from `references/body-structure.md`. The defaults there work for most repos.

## Checklist items

Most templates include a checklist. Common items:

- `[ ] I have read CONTRIBUTING.md`
- `[ ] My code follows the style guide`
- `[ ] I have added tests`
- `[ ] I have updated documentation`
- `[ ] I have updated the changelog`

Treat these as the team's bar for what they want every PR to clear. Tick honestly:

- If you added tests, tick the box. If you didn't (and didn't need to—e.g. doc-only PR), leave it and add a one-line note explaining why in the relevant section.
- If a CHANGELOG.md exists in the repo and the team's recent PRs all update it, update it. Don't tick the box without doing the work.
- Never tick "I have read CONTRIBUTING.md" without actually checking it—often it has commit-message rules or test conventions you need to follow.

## Multi-template repos

Some repos have separate templates for `feat`, `fix`, `chore`, etc. (`.github/PULL_REQUEST_TEMPLATE/feat.md`, `fix.md`, …). GitHub picks one via a `?template=feat.md` query string. When drafting, choose the template that matches the change. Tell the user the URL suffix to add when opening the PR if it's not obvious:

```
Open with: gh pr create --web --template feat.md
```

or

```
After pushing, go to:
https://github.com/<owner>/<repo>/compare/<base>...<head>?template=feat.md
```

## Updating an existing PR

If `gh pr view` shows a PR already open on this branch:

- Read its current body (`gh pr view --json body -q .body`).
- Identify which sections were filled by the human vs. left as template placeholders.
- Only overwrite placeholder sections and clearly auto-generated ones. Preserve anything the human wrote (review responses, context notes, scope clarifications).
- Use `gh pr edit --body "$(cat <<'EOF' … EOF)"` to push the update—this replaces the body wholesale, so include the preserved human content in your new draft.

Always confirm with the user before editing an open PR's description.
