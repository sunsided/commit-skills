---
name: address-review
description: Use this skill whenever the user wants to act on pull-request review feedback: "fix the review comments", "address the PR feedback", "go through the reviewer's comments", "respond to the review", "handle the requested changes on my PR", "deal with the review threads", "reply to the comments on the PR", "the reviewer left some comments, sort them out", or "/address-review". This is the skill for *answering* a review, not writing one. It reads the review comments off the current branch's PR via the GitHub API (or comments the user pastes in), triages each as a defect, suggestion, opinion, or question, fixes what's valid as repo-style commits, and posts a reply in each thread, citing the fixing commit's short SHA as a bare hash so GitHub auto-links it, pushing before replying, and never auto-resolving the thread. Always reach for this skill rather than hand-rolling it whenever a request involves reviewer comments, code-review feedback, requested/change requests, PR review threads, or "what the reviewer asked for", even when the user names neither the skill nor a PR number. The in-thread reply mechanics and SHA auto-linking are easy to get wrong by hand, so prefer this skill over doing it inline.
---

# address-review

A code review is a conversation, not a checklist. On the other side is a person who spent their attention reading your change and wrote down what they found. Addressing that review well means two things at once: making the code better where they're right, and *closing the loop* on every point so the reviewer can see what you did with their feedback without having to re-read the whole diff.

The failure mode to avoid is silent dismissal — quietly fixing some things, ignoring others, and leaving the reviewer to guess which is which. Every comment that asks for something or asks a question gets a reply. You don't have to agree with all of them; you do have to answer.

Two things this skill explicitly does **not** do:

- **It doesn't fix things just to make a thread go away.** If a suggestion is wrong, or a matter of taste you'd decide differently, reply with your reasoning instead of caving. A review is a place to disagree honestly. Reviewers respect a reasoned "I'd keep it as-is because…" far more than a reluctant change that makes the code worse.
- **It doesn't resolve threads for the reviewer.** You reply; they decide whether their concern is met and resolve it. Auto-resolving steals that judgment and hides unfinished disagreements.

## Work order

1. **Find the comments.**
   - Default: locate the PR for the current branch with `gh pr view --json number,url,headRefName,baseRefName`. If there's no PR, say so and ask the user for the PR number/URL or for the comments themselves.
   - Fetch all three surfaces (inline threads are primary; also the review summary bodies and the general PR conversation). See `references/github-api.md` for the exact calls, pagination, and how to group inline comments into threads.
   - Skip threads already marked resolved or clearly outdated — don't re-litigate settled points. Note when a comment is outdated because the code under it moved.
   - **User-provided comments:** if the user pasted comments (or pointed at a different PR), work from those. When the text doesn't carry a comment ID you can reply to programmatically, still fix + commit, and hand back reply *text* for the user to paste.

2. **Triage each comment.** Sort every comment into one of these, then act accordingly. Detail and worked reply examples live in `references/triage.md`.

   | Kind | What it is | Default action |
   |---|---|---|
   | **Defect** | A real bug, missing case, wrong logic, security/perf hole | Fix + reply citing the SHA |
   | **Suggestion** | A reasonable improvement / nit / refactor | Fix if you agree and it's worth it; otherwise reply with reasoning |
   | **Opinion** | Taste, no clear right answer | Fix only if cheap and you concur; else reply acknowledging the tradeoff |
   | **Question** | Reviewer wants to understand something | Answer in the reply. If the question exposes a real problem, also fix |
   | **Praise / non-actionable** | "nice", "👍" | No reply needed; don't clutter the thread |

   The lines blur, and that's fine — the point of triage isn't a perfect label, it's choosing between *fix-and-reply* and *reply-only*, and never *do-nothing-and-stay-silent*.

3. **Make the fixes, as real commits.** Edit the code for everything in the fix-and-reply bucket. Commit the work matching the repo's existing commit style (Conventional Commits vs. plain imperative, Why-first body when the reason isn't obvious — the same detection the `commit` skill uses). Group related fixes into coherent commits; one commit can address several nearby comments, and you'll cite that one SHA in each of their replies. Capture each short SHA with `git rev-parse --short HEAD`.

4. **Draft the plan and confirm before anything posts.** Present a compact table: each comment, your verdict (fix / reply-only), the one-line reply you'll post, and the SHA if fixed. Posting replies and pushing are outward-facing — wait for the user's go-ahead. This is also their chance to overrule a verdict.

5. **Push, then reply — in that order.** A bare SHA only becomes a clickable commit link once that commit exists on GitHub, so the branch must be pushed *before* the replies reference it. Push (`git push`), then post each reply to its thread. See `references/github-api.md` for the reply endpoints.

## Citing the fixing commit

When a reply reports a fix, name the commit by its short SHA **as bare text** — `Fixed in 4f2a1c8`, never `` `4f2a1c8` ``. GitHub auto-links a 7-to-40-character hex SHA to the commit when it's unwrapped; wrapping it in backticks suppresses that, leaving the reviewer a dead string they have to go hunt for. Backticks are still right for *code* identifiers in the same sentence — only the SHA stays bare.

**Lead with it.** Open the reply with the disposition — `Fixed in 4f2a1c8.` — then the explanation. A reviewer working through a wall of threads wants the outcome first; front-loading it lets them confirm "yes, handled" and move on without reading the rationale, and read the rationale only when they care.

> Fixed in 4f2a1c8. The expiry check uses `>=` now, so a token expiring on the exact boundary tick counts as expired.

This is also why push precedes reply (step 5): an SHA GitHub doesn't have yet won't resolve to a link.

## Writing the replies

A reply is professional communication, the same register as a PR body. Keep it short — one thread, one focused reply.

- **Fixed it:** open with the disposition and SHA, then say what changed and, briefly, that you got why it mattered. "Fixed in 4f2a1c8. The check uses `>=` now, so a token expiring on the exact boundary tick counts as expired." Skip "Thanks for catching this!" preambles on every thread; an occasional genuine "good catch" is fine, a reflexive one on all twelve is noise.
- **Won't fix / disagree:** give the reason and, where useful, the alternative you chose. "I'd keep the explicit loop here — the comprehension version allocates an intermediate list on every call and this is in the hot path. Open to a different read if you've measured otherwise." Stay collegial; you're defending a decision, not winning a fight.
- **Answering a question:** answer it directly, point to `file:line` when that's the real answer. If the question reveals a gap, fix it and say so.
- **Need a decision you can't make:** don't guess. Ask the reviewer the specific question back, or flag it for the user.

Never write tooling chatter ("I ran the tests", "generated by…"), never "As an AI", no co-authored-by lines unless the user asked.

## Edge cases

- **No PR on the branch.** Ask for the PR number/URL, or take pasted comments. Don't invent a PR.
- **Bot reviewers** (CodeRabbit, Copilot, linters). Treat them like any reviewer: act on the real findings, and dismiss noise with a brief reasoned reply rather than silence.
- **Comment you genuinely can't address** (needs a product call, missing context). Reply asking the specific question; surface it to the user. Don't paper over it with a vague acknowledgement.
- **A fix turns out larger than the PR's scope.** Reply proposing a follow-up issue rather than ballooning the diff; file it if the user agrees, and link it.
- **The reviewer is wrong on the facts.** Show, don't argue — point at the line or test that demonstrates the current behavior, neutrally.

## Reference files

- `references/github-api.md` — fetching all three comment surfaces (REST + GraphQL), grouping threads, pagination, the reply endpoints, and the push-before-reply sequencing.
- `references/triage.md` — the classification taxonomy in depth, with a worked reply for each kind and the judgment calls between them.
