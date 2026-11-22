## Generic

If the workspace was clean (no pending changes) before a prompt, after every code change, commit the changes to git under the AI agent name.  Include the orignal prompt, the model, any relevant tool calls and responses in the commit message.  The commit message is for diagnostics and logging.  Include, in particular, any caveats or open questions.

For _any_ shell command which is missing, let me know so I can install it async.  I am actively building up a list of useful tools for code editing etc.

This is a Nix managed system: any required dependency for a project, if available in nixpkgs, give me the package name and I will add it to the global nix config async.

## OCaml

In a Dune project: Do not wait for any build command (dune build or dune exec) for longer than 20 seconds; particularly: do not wait for rebuilding dependencies.  Let me build them async.

Prefer ppx-jane over specifying individual ppxs from janestreet.

## Nix

In projects that are buildable with both Nix _and_ native tooling, make sure any change keeps the native tooling, functioning, but don’t break the nix build either.  In those cases, dev is native tooling first.
