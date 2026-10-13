{ toggle-charging, writeShellApplication }:

writeShellApplication {
  name = "clamp-smc-charging";
  text = builtins.readFile ./clamp-smc-charging;
  runtimeInputs = [ toggle-charging ];
  # pmset
  meta.platforms = [ "aarch64-darwin" ];
}
