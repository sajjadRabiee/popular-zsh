# Why popular.zsh?

There are bigger tools for shell history, snippets, and command search.

`popular.zsh` is for the smaller use case:

- you want a plain text file
- you want a tiny script (with small modules under `lib/popular/`)
- you want fast repeatable commands
- you want lightweight templates and optional secrets beside the store

It is intentionally simple.

That simplicity is the feature.

Because the store is a plain text file and there are `pexport` / `pimport` helpers, you can treat favorites like tiny reusable scripts without adopting a heavier toolchain—while keeping sensitive values in a separate secrets file when you use `<<placeholders>>`.

The `pimport -R owner/repo` flag extends this to a community level: anyone can publish a **popular-pack** (a repo with a `commands.pop` file) and share it as a single import line. Teams bootstrap shared shortcuts in seconds; individuals can start from a 1 000-command starter pack and prune what they do not need.
