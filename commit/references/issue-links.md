# Finding issue links

Where the ticket/issue ID for a change lives, and how to surface it in the commit body.

## Sources, cheapest first

1. **Branch name.** Run `git rev-parse --abbrev-ref HEAD`. Look for patterns like:
   - `feat/MED-481-session-booking` → `MED-481`
   - `bugfix/PROJ-42-token-refresh` → `PROJ-42`
   - `mmayer/123-cleanup` → `#123` (GitHub-style)
   - `fix-1234` → `#1234` (loose convention)

   Heuristic: any uppercase token of the form `[A-Z]+-\d+` is almost certainly a Jira/Linear/YouTrack key. Standalone `\d{1,5}` near the end of a branch name is likely a GitHub/GitLab issue number.

2. **Existing commits on the branch.** Run `git log --pretty=%B <base>..HEAD` where `<base>` is the merge base with main/master. If earlier commits on this branch reference an issue (`Refs: MED-481`, `Fixes #123`), reuse it.

3. **Code annotations in the diff.** Grep the diff for:
   - `TODO(PROJ-42)`, `FIXME(#123)`
   - `// see MED-481`, `// part of #123`

   Sometimes the user added a `TODO` referencing the very ticket the change is about.

4. **User context in the current conversation.** If the user has said anything like "this is for MED-481" earlier in the chat, use it.

5. **MCP servers (Jira / YouTrack / Linear / GitHub).** Only after the cheaper sources fail. Before calling an MCP, ask the user: "I couldn't find an issue link in the branch or commits—want me to check Jira for tickets matching this work, or skip?" Reasons to ask:
   - MCP calls cost tokens and time.
   - The user may know the answer faster than the MCP search.
   - There may be no ticket at all (drive-by fixes, personal projects).

## Formats by host

Match the format the repo already uses (see `git log`). Common ones:

| Form | When to use |
|---|---|
| `Refs: MED-481` | Generic—works for Jira, Linear, YouTrack. Default if unsure. |
| `Closes #123` | GitHub/GitLab; auto-closes the issue on merge. Only if the commit actually closes it. |
| `Fixes #123` | GitHub/GitLab; same as Closes but more semantic for bugs. |
| `MED-481` (bare) | Some teams put it in the subject prefix; only if history does. |
| `Co-authored-by: …` | Do **not** add unless explicitly requested. |

## When to put the link where

- **Subject:** only if the repo style already does (e.g. `MED-481: Add booking endpoint`). Don't add it just because it exists.
- **Footer (last paragraph of body):** the default location. One line, one link.
- **Multiple issues:** stack them: `Refs: MED-481, MED-482`. Don't make up a single ticket that "covers" them.

## When there's no ticket

That's fine. Many commits don't need one (typo fixes, internal refactors, personal-repo work). Don't fabricate a placeholder. Don't write `Refs: N/A` or `Issue: none`. Just leave it out.

## When the user provides one explicitly

Use it verbatim. Even if it doesn't match the format you'd have inferred, trust the user.
