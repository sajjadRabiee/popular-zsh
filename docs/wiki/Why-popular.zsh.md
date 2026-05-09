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
