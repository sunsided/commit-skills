# Detecting and following the repo's commit style

You want commits that look like they were written by someone on the team. That means matching the style already in use, not imposing a "best practice."

## Detection order

Check sources in this order; stop at the first one that gives you a clear answer.

1. **Explicit policy files.** Look in the repo root and `docs/` for:
   - `CONTRIBUTING.md` / `CONTRIBUTING`
   - `COMMITS.md`, `COMMIT_CONVENTION.md`
   - `.gitmessage` or `commit.template` configured via `git config --get commit.template`
   - Pre-commit hooks under `.husky/`, `.git/hooks/`, `lefthook.yml` that enforce a format (e.g. commitlint configs in `.commitlintrc*`, `commitlint.config.*`)
   - PR template references to commit style in `.github/`

   If any of these specify a style, use it verbatim. They override observed history (history may predate the policy).

2. **Observed history.** Run `git log --no-merges --pretty=format:'%s' -50` and look at the distribution. Classify each subject and pick the dominant pattern. Tiebreaker: prefer the more recent half of the sample, since style can drift over time.

3. **Fallback: Conventional Commits.** If nothing above is conclusive (e.g. brand new repo, or a wild mix), use Conventional Commits with no scope.

## Styles you'll see

### Conventional Commits

`<type>(<scope>)!: <subject>` where:
- `type` is one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. **Stick to this set.** Do not invent new types (`bench:`, `infra:`, `tool:`, etc.)—they look conventional but break tooling that scans for the standard set (changelog generators, commit-msg linters like commitlint). If history shows a non-standard type already in use, follow history; otherwise pick the closest match from the standard set (a benchmark addition is `perf:` or `test:`; a Taskfile change is `chore:` or `build:`).
- `scope` is optional and conventionally a module or package name. Look at recent commits to learn which scopes are in use; do not invent new ones.
- `!` marks a breaking change (and `BREAKING CHANGE:` footer in the body).

Example: `feat(auth): allow login via passkey`

### Plain imperative

A capitalized verb at the start, no prefix, no scope. The classic "what would this commit do if applied":

`Add session booking endpoint`
`Fix buffer underrun in calendar renderer`
`Refactor token refresh into a single helper`

### Gitmoji / emoji prefixed

`:sparkles: add session booking endpoint`. Rare but unmistakable in history. Match the emoji vocabulary already in use.

### Ticket-prefixed

`MED-481: Add session booking endpoint` or `[MED-481] Add session booking endpoint`. Common in repos backed by Jira or Linear without Conventional Commits. The ticket prefix replaces the scope.

### Hybrid (Conventional + ticket footer)

Subject is Conventional Commits, ticket goes in a `Refs:` or `Closes:` footer. This is the most common style in well-maintained repos.

## Subject rules that apply across styles

- Imperative mood: "Add", not "Added" or "Adds".
- ≤72 chars hard, aim for ≤50. The trailing `.` is dropped.
- No trailing tooling tags (no "(via Claude)", no "(WIP)"—if it's WIP, don't commit it).
- The subject must be understandable without the body. "Fix bug" is not acceptable; "Fix off-by-one in pagination cursor" is.

## When the user's repo style conflicts with the user's request

If history is plain imperative but the user asks for Conventional Commits ("commit this with conventional commit messages"), the user's request wins for this session—but mention the mismatch once, in case they want to update CONTRIBUTING.md to match.

## Examples of classification

| Subject in `git log` | Classified as |
|---|---|
| `feat(api): expose /health endpoint` | Conventional Commits, scope=api |
| `Add /health endpoint` | Plain imperative |
| `MED-481 Add /health endpoint` | Ticket-prefixed |
| `chore: bump axios to 1.7.0` | Conventional Commits, no scope |
| `:bug: fix race in session lock` | Gitmoji |

If 40+ out of 50 recent commits match one of these, that's your style. If it's a 30/20 split, the more recent half wins.
