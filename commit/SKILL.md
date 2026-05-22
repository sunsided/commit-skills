---
name: commit
description: Use whenever the user wants to commit changes, split a working tree into commits, write a commit message, or says anything like "commit this", "make commits for these changes", "write a commit message", or "/commit". Detects the repository's commit style (Conventional Commits, plain imperative, etc.), groups unstaged + staged changes into semantically-coherent commits, writes a concise subject plus an extended body covering rationale, before→after, findings, and issue links, then stages and commits each group after confirming the plan with the user. Trigger even when the user does not explicitly say "skill"—any request to commit, stage, or describe local changes counts.
---

# commit

Turns a dirty working tree into a clean series of well-described commits. The output the user cares about is **a sequence of `git commit`s that a reviewer can follow without you in the room**: each commit is one logical change, its subject states intent in the repo's house style, and its body answers the questions a reviewer would otherwise have to dig out of the diff.

Work in this order:

1. **Read the working tree.** Run `git status --short` and `git diff` (and `git diff --staged` if anything is already staged). Read `git log --oneline -30` to see how this repo phrases commits. Note the current branch name—it often carries the issue ID.
2. **Detect the commit style.** See `references/styles.md`. CONTRIBUTING / .gitmessage / commit template > observed history > Conventional Commits fallback.
3. **Group changes into logical commits.** See `references/splitting.md`. Group by *intent*, not by directory.
4. **Find issue links.** See `references/issue-links.md`. Only escalate to MCPs after confirming with the user.
5. **Draft the plan.** Show the user the commits you intend to make: ordered list of `subject` lines with the files in each group. Keep it skimmable.
6. **Draft the messages.** Subject + body per commit, in the detected style. See `references/messages.md`.
7. **Confirm, then execute.** Stage and commit each group. Stop and ask if anything looks ambiguous; do not silently fold orphan files into the last commit.

## Principles

**Group by intent, not by path.** A `Taskfile.dist.yaml` added alongside benchmark code is part of the benchmark commit. The same file added alongside an unrelated API change is its own commit. The diff alone cannot tell you which case you're in; the surrounding files and the user's recent work do. When in doubt, ask.

**One commit, one reason to revert.** If a reviewer might want to revert part of a commit independently, that's a sign it should have been two commits. Equally, do not split changes that *must* land together (e.g. an API signature change and the call sites that adapt to it)—a broken intermediate commit is worse than a fat one.

**Subjects state intent, bodies state mechanics.** The subject is what changed and why someone should care. The body explains how the code now behaves differently, anything surprising you noticed while making the change, and where the issue lives. Bodies are optional for trivial commits (typo fix, dep bump). They are not optional for behavior changes.

**Match the repo, do not impose a style.** If history is plain imperative ("Add user lookup endpoint"), do not switch to `feat(api): add user lookup endpoint`. If history is Conventional Commits, follow the convention precisely, including scopes already in use.

**Never include tooling artifacts in the message.** No "written with Claude", no "verified by running tests", no AI footers or co-authored-by lines unless the user has explicitly asked for them. The message is for humans reading `git log` six months from now.

## Execution

After the user approves the plan:

```bash
git reset                                # clear stage if needed
git add <files for commit 1>             # explicit file list; never `git add -A`
git commit -m "<subject>" -m "<body>"    # or HEREDOC for multi-paragraph bodies
# repeat per group
```

Use a HEREDOC for multi-paragraph bodies so newlines survive:

```bash
git commit -m "$(cat <<'EOF'
feat(session): add booking endpoint

Adds POST /sessions/book. Before, sessions were created implicitly on
first message; now the client explicitly reserves a slot and gets a
session_id back, which removes the race between two clients claiming
the same therapist window.

Refs: MED-481
EOF
)"
```

**Safety:** stage files by explicit name, not `-A` or `.`, to avoid grabbing `.env` or build artifacts. If the diff contains anything that looks like a secret, stop and flag it before committing. Never `--amend` a commit that is already pushed.

## Handing off

When all commits are made, run `git status` and `git log --oneline <base>..HEAD` and show the result. Mention anything you deliberately left out of the commits (e.g. untracked scratch files) so the user knows what's still dirty.

## Reference files

- `references/styles.md` — detect and follow the repo's commit style.
- `references/splitting.md` — heuristics for grouping changes by intent.
- `references/issue-links.md` — where issue IDs live and how to surface them.
- `references/messages.md` — subject + body templates with worked examples.
