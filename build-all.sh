#!/usr/bin/env bash

# Use this in CI

set -eu -o pipefail

export NIXPKGS_ALLOW_UNFREE=1

nix-instantiate  --json --eval --expr '
  let
	p = import <nixpkgs> {};
	f = builtins.getFlake (builtins.toString ./.);
  in
	builtins.attrNames f.packages.${p.system}' | \
jq -r | \
jq -r ".[]" | \
while read prog ; do
  nix build --impure --no-link --print-build-logs  ".#$prog"
done
