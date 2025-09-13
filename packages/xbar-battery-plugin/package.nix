{
  lib,
  system,
  callPackage,
}:

(lib.packagesFromDirectoryRecursive {
  inherit callPackage;
  directory = ./per-arch;
}).${system} or { }
