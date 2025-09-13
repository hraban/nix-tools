# Like nix-collect-garbage --delete-older-than 30d, but doesn’t delete anything
# that was _added_ to the store in the last 30 days. Creates a fresh GC root for
# those paths in /nix/var/nix/gcroots/rotating, from where stale entries are
# only cleared out the next time you run this again.
{
  findutils,
  lib,
  nix,
  sqlite,
  writeShellApplication,
}:

writeShellApplication {
  name = "nix-collect-old-garbage";
  runtimeInputs = [
    sqlite
    findutils
    nix
  ];
  text = builtins.readFile ./nix-collect-old-garbage.sh;
  derivationArgs = {
    meta.license = lib.licenses.agpl3Only;
  };
}
