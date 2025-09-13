{
  _1password-cli,
  awscli,
  lib,
  writeShellApplication,
}:
writeShellApplication {
  runtimeInputs = [
    _1password-cli
    awscli
  ];
  text = builtins.readFile ./aws-1password.sh;
  name = "aws-1p";
  derivationArgs = {
    meta.license = lib.licenses.agpl3Only;
  };
}
