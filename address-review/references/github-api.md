# GitHub mechanics for reading and replying to review comments

All commands use `gh`, which substitutes `{owner}` and `{repo}` from the current repository automatically. The PR number is `{pr}` below — get it once with `gh pr view --json number -q .number`.

## The three comment surfaces

A PR review is spread across three different APIs. You need all three; inline threads are where most actionable feedback lives.

### 1. Inline review comments (the threads) — primary

Line-anchored comments, the ones with a reply box under them. These are the bulk of a review.

```bash
gh api --paginate repos/{owner}/{repo}/pulls/{pr}/comments
```

Each object carries the fields you need:

- `id` — the comment's database ID (used to reply).
- `in_reply_to_id` — present on replies; **absent on the root comment of a thread**. Group by this: a root plus everything pointing back to it (directly or transitively) is one thread.
- `body`, `user.login` — the text and who wrote it.
- `path`, `line` (and `original_line`), `diff_hunk` — where it's anchored. If `line` is null but `original_line` is set, the comment is **outdated** (the code under it changed).

A compact view to reason over:

```bash
gh api --paginate repos/{owner}/{repo}/pulls/{pr}/comments \
  --jq '.[] | {id, in_reply_to_id, user: .user.login, path, line, body}'
```

### 2. Review summary bodies

The top note a reviewer leaves when they submit ("Approve" / "Request changes" / "Comment"), separate from any inline comments.

```bash
gh api --paginate repos/{owner}/{repo}/pulls/{pr}/reviews \
  --jq '.[] | select(.body != "") | {id, user: .user.login, state, body}'
```

`state` is `APPROVED`, `CHANGES_REQUESTED`, or `COMMENTED`. There's no thread to reply *into* here — respond to its points either inline (if they map to lines) or with a single general PR conversation comment that addresses the summary.

### 3. General PR conversation (issue comments)

Free-floating comments on the PR not tied to a diff line.

```bash
gh api --paginate repos/{owner}/{repo}/issues/{pr}/comments \
  --jq '.[] | {id, user: .user.login, body}'
```

These don't thread. "Reply" = post a new conversation comment, quoting or `@`-mentioning so it's clear what you're answering.

## Grouping threads + skipping resolved ones (GraphQL)

REST doesn't tell you whether a thread is resolved. GraphQL does, and it groups comments into threads for you — use it to decide what to skip:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          isResolved
          isOutdated
          comments(first:50){
            nodes{ databaseId author{login} path line body }
          }
        }
      }
    }
  }
}' -F owner='{owner}' -F repo='{repo}' -F pr=PRNUMBER \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved | not)
        | {outdated: .isOutdated,
           root: .comments.nodes[0].databaseId,
           comments: [.comments.nodes[] | {id: .databaseId, user: .author.login, body}]}'
```

The `databaseId` of the **first** comment in a thread is the `id` you reply to. `isResolved == true` threads are settled — skip them. `isOutdated == true` means the anchored code moved; read it, but the line reference may be stale.

## Replying

### Reply into an inline thread

Reply to the thread by posting against its **root** comment id:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{root_comment_id}/replies \
  -f body='Fixed in 4f2a1c8. The expiry check uses >= now, so the boundary tick counts as expired.'
```

(Equivalently, `POST repos/{owner}/{repo}/pulls/{pr}/comments` with `-F in_reply_to={root_comment_id}`. The `/replies` form is simpler.)

### Reply to a review summary or a conversation comment

No thread to enter — post one general PR comment:

```bash
gh api repos/{owner}/{repo}/issues/{pr}/comments \
  -f body='Addressed the two CHANGES_REQUESTED points: null-guard in 4f2a1c8, naming in 9b1e0a2.'
```

### Bodies with special characters

For multi-line or shell-hostile bodies, pass the body from a file to avoid quoting problems:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{root}/replies -F body=@reply.txt
```

## Sequencing: push before you reply

A short SHA only renders as a clickable commit link once GitHub has that commit. So the order is non-negotiable:

1. Make every fix and commit locally.
2. `git push` the branch (confirm with the user first — it's outward-facing).
3. *Then* post the replies that cite those SHAs.

Reply before push and the reviewer gets a bare string that links nowhere.

## Quick reference

| Need | Call |
|---|---|
| PR number for branch | `gh pr view --json number -q .number` |
| Inline comments | `gh api --paginate repos/{owner}/{repo}/pulls/{pr}/comments` |
| Review summaries | `gh api --paginate repos/{owner}/{repo}/pulls/{pr}/reviews` |
| Conversation comments | `gh api --paginate repos/{owner}/{repo}/issues/{pr}/comments` |
| Threads + resolved state | `gh api graphql … reviewThreads` (above) |
| Reply in thread | `gh api …/pulls/{pr}/comments/{root}/replies -f body=…` |
| Reply on conversation | `gh api …/issues/{pr}/comments -f body=…` |
| Short SHA | `git rev-parse --short HEAD` |
