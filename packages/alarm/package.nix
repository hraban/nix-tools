# Darwin-only because of ‘say’
{ lispPackagesLite }:

with lispPackagesLite;
lispScript {
  name = "alarm";
  src = ./alarm.lisp;
  dependencies = [
    arrow-macros
    f-underscore
    inferior-shell
    local-time
    trivia
    lispPackagesLite."trivia.ppcre"
  ];
  installCheckPhase = ''
    $out/bin/alarm --help
  '';
  doInstallCheck = true;
  meta.platforms = [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
