Commit and push the changes in the current git repository.

Behavior:
1. Stage only the files actually created or modified in this conversation.
   - Don't touch pre-existing changes unrelated to the session (e.g. `.claude/settings.local.json` and the like).
   - If it's unclear what to stage, check `git status`, point it out to the user, then proceed.
2. Read the diff of the staged changes and write a message following this repo's commit convention.
   - Match the format by referring to recent `git log` (e.g. `feat(scope):`, `fix(scope):`, `docs(scope):`, `chore:`).
   - Subject is a one-line summary. If there are multiple changes, briefly add what/why in the body.
3. After committing, push the current branch.
   - If there's no upstream, `git push -u origin <current-branch>`.

Notes:
- If the session touched multiple repositories, target only the repository in the current working directory (cwd). If other repositories also need committing, let the user know.
- If the push fails (remote ahead, conflict, etc.), don't force-push — report the situation as-is.

If extra arguments are given, use them as a commit message hint: $ARGUMENTS
