{
  lib,
  lispPackagesLite,
  smc-fuzzer,
  writeShellScript,
}:

let
  smc = lib.getExe smc-fuzzer;
  smc_on = writeShellScript "smc_on" ''
    exec ${smc} -k CHTE -w 00000000
  '';
  smc_off = writeShellScript "smc_off" ''
    exec ${smc} -k CHTE -w 01000000
  '';
in
with lispPackagesLite;
lispScript {
  name = "control-smc.1m.lisp";
  src = ./control-smc.1m.lisp;
  dependencies = [
    cl-interpol
    cl-ppcre
    inferior-shell
    trivia
  ];
  inherit smc smc_on smc_off;
  passthru.sudo-binaries = [
    smc_on
    smc_off
  ];
  meta.platforms = [ "aarch64-darwin" ];
  postInstall = ''
    export self="$out/bin/$name"
    substituteAllInPlace "$self"
  '';
}
