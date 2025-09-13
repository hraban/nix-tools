# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

# Use this to wait for the /nix/store to be available in a launch daemon.

{
  exec,
  lib,
  stdenv,
}:
assert lib.assertMsg stdenv.isDarwin "wait4path only works on Darwin";
[
  "/bin/sh"
  "-c"
  "/bin/wait4path /nix/store &amp;&amp; ${exec}"
]
