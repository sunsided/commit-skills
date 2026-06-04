# commit-skills

Three skills for Claude Code:

- **`commit`** — turns a dirty working tree into a clean series of well-described commits. Detects the repo's commit style, groups changes by intent, writes Why-first bodies, surfaces issue links, then stages and commits.
- **`pr`** — drafts pull-request titles and bodies oriented around what a human reviewer needs: summary, motivation, key changes, risks, and an explicit "where to start reading" section. Matches the repo's PR template if present. Never enumerates commits, never mentions tooling.
- **`address-review`** — works the *other* side of a PR: reads the review comments off the current branch's PR (or ones you paste in), judges each as a defect, suggestion, opinion, or question, fixes what's valid as repo-style commits, and replies in-thread to every actionable comment — citing the fixing commit's short SHA as a bare, auto-linking hash. Pushes back with reasoning instead of caving on wrong suggestions; never silently drops a comment; leaves thread-resolving to the reviewer.

Built and validated with [`skill-creator`](https://github.com/anthropics/claude-code/tree/main/plugins/skill-creator).

## Layout

```
commit-skills/
├── commit/
│   ├── SKILL.md
│   └── references/   # style detection, splitting heuristics, issue links, message templates
├── pr/
│   ├── SKILL.md
│   └── references/   # body structure, review guidance, PR templates
├── address-review/
│   ├── SKILL.md
│   └── references/   # github comment APIs, triage taxonomy + reply cookbook
└── fixtures/         # reproducible git-repo scenarios used by evals
```

The `*-workspace/` directories (`commit-workspace/`, `pr-workspace/`, `address-review-workspace/`) hold per-iteration eval results; they're not part of the installed skill.

## Installation

### Option A — symlink into the personal skills dir (recommended for local use)

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/commit"         ~/.claude/skills/commit
ln -s "$(pwd)/pr"             ~/.claude/skills/pr
ln -s "$(pwd)/address-review" ~/.claude/skills/address-review
```

Restart Claude Code (or run `/reload-plugins` if loaded via plugin) to pick them up.

### Option B — install the packaged `.skill` files

```bash
cd commit-skills
python3 -m scripts.package_skill commit          # produces commit.skill
python3 -m scripts.package_skill pr              # produces pr.skill
python3 -m scripts.package_skill address-review  # produces address-review.skill
```

The packaging script lives in the `skill-creator` plugin (`~/.claude/plugins/.../skill-creator/scripts/`). Adjust the invocation to your local path.

Use the resulting `.skill` files via the Claude Code skill installer (`/plugin install` or drag-and-drop in the UI, depending on your version).

### Option C — copy into a project's `.claude/skills/`

For a single repo:

```bash
mkdir -p /path/to/repo/.claude/skills
cp -r commit         /path/to/repo/.claude/skills/
cp -r pr             /path/to/repo/.claude/skills/
cp -r address-review /path/to/repo/.claude/skills/
```

Commit the result if the repo opts into per-project skills.

## Usage

The skills auto-trigger on natural-language requests. Examples:

| Request | Skill |
|---|---|
| "commit this" | `commit` |
| "split these changes into proper commits before I open a PR" | `commit` |
| "write a commit message for the auth refactor" | `commit` |
| "open a PR against main" | `pr` |
| "draft a PR description, base is develop" | `pr` |
| "make a pull request and link MED-481" | `pr` |
| "fix the review comments on my PR" | `address-review` |
| "go through the reviewer's feedback and reply in the threads" | `address-review` |
| "address the requested changes on #418, cite the fix commits" | `address-review` |

The skills also respond to slash commands: `/commit`, `/pr`, and `/address-review`.

## How they work, briefly

The skills follow the same shape:

1. **Look at the actual state.** `git status`, `git log`, `git diff`, branch name—nothing is guessed. `address-review` adds the PR's review comments (`gh api` across inline threads, review summaries, and conversation comments).
2. **Detect the repo's style.** Conventional Commits vs. plain imperative vs. ticket-prefixed; for PRs, the `.github/pull_request_template.md` if present. `address-review` reuses the same commit-style detection for its fix commits.
3. **Apply judgment.** Group commits by intent (a Taskfile alongside a benchmark is one commit; alongside an unrelated API change it's two). For PRs, lead with what a reviewer needs to know. For reviews, triage each comment into fix-and-reply vs. reply-only—and never silently drop one.
4. **Confirm, then execute.** The `commit` skill stages and commits per group. The `pr` skill emits the title + body as text and optionally runs `gh pr create`. The `address-review` skill shows a plan, then (on your go-ahead) pushes and posts in-thread replies citing the fix SHAs—push first, so the bare SHA auto-links.

Each skill has a `references/` directory with the details:

- `commit/references/styles.md` — commit-style detection
- `commit/references/splitting.md` — when to split, when to keep together
- `commit/references/issue-links.md` — where to look for ticket IDs
- `commit/references/messages.md` — subject + body templates (Why-first)
- `pr/references/body-structure.md` — PR body templates by change type
- `pr/references/review-guidance.md` — writing the "review notes" section
- `pr/references/pr-templates.md` — matching `.github/pull_request_template.md`
- `address-review/references/github-api.md` — fetching the three comment surfaces and replying in-thread
- `address-review/references/triage.md` — the comment taxonomy and a reply cookbook

## Re-running the evals

Each skill has `evals/evals.json` and a set of `fixtures/` shell scripts. The fixtures set up reproducible git repos with realistic working-tree states (mixed changes, coupled tooling, ticket-prefixed history, feature branch with template, etc.).

To regenerate a fixture into a target directory:

```bash
bash fixtures/commit/mixed-changes.sh /tmp/eval-repo
```

The `address-review` fixtures build a branch whose code contains the exact issues a reviewer would flag; the review comments themselves are supplied in the eval prompt (the skill's "user-provided comments" path), so the evals stay hermetic and don't need a live GitHub PR. The live `gh` fetch-and-reply path is therefore exercised by hand, not by the eval harness.

The evals themselves use `skill-creator`'s eval harness; see that plugin's documentation.

## What's intentionally not in the skills

- **No tooling attribution.** No "written with Claude", no `Generated-by:` trailers, no co-authored-by lines. Commit messages and PR descriptions are durable artifacts read by humans long after the tool that wrote them is forgotten.
- **No commit list in PRs.** The reviewer sees commits on the "Files changed" tab; restating them in the body wastes their attention.
- **No verification chatter in PRs.** "Verified by running `cargo test`" belongs in CI, not the PR body.
- **No backticked SHAs in review replies.** `address-review` writes the fixing commit hash bare (`Fixed in 4f2a1c8`), because GitHub only auto-links an unwrapped hex SHA. It also never auto-resolves a reviewer's thread, and never makes a change it disagrees with just to close one.

## License

MIT. See `LICENSE`.
