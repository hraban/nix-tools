{
  lib,
  lispPackagesLite,
  makeWrapper,
  toggle-charging,
  writeShellScript,
}:

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
  passthru.sudo-binaries = [ (lib.getExe toggle-charging) ];
  nativeBuildInputs = [ makeWrapper ];
  meta.platforms = [ "aarch64-darwin" ];
  postInstall = ''
    self="$out/bin/$name"
    substituteInPlace "$self" --replace-fail @self@ "$self"
    wrapProgram "$self" --suffix PATH : "${lib.makeBinPath [ toggle-charging ]}"
  '';
}
