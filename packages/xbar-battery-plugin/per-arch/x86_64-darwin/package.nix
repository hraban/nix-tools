{ bclm, lispPackagesLite }:

with lispPackagesLite;
lispScript {
  name = "battery.30s.lisp";
  src = ./battery.30s.lisp;
  dependencies = [
    arrow-macros
    cl-interpol
    inferior-shell
    trivia
  ];
  inherit bclm;
  passthru.sudo-binaries = [ bclm ];
  meta.platforms = [ "x86_64-darwin" ];
  postInstall = ''
    export self="$out/bin/$name"
    substituteAllInPlace "$self"
  '';
}
