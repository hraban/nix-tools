{
  fetchzip,
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  name = "bclm";
  # There’s a copy of this binary included locally en cas de coup dur
  src = fetchzip {
    url = "https://github.com/zackelia/bclm/releases/download/v0.0.4/bclm.zip";
    hash = "sha256-3sQhszO+MRLGF5/dm1mFXQZu/MxK3nw68HTpc3cEBOA=";
  };
  installPhase = ''
    mkdir -p $out/bin/
    cp bclm $out/bin/
  '';
  dontFixup = true;
  meta = {
    platforms = [ "x86_64-darwin" ];
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    downloadPage = "https://github.com/zackelia/bclm/releases";
    mainProgram = "bclm";
  };
}
