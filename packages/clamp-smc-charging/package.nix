{ smc-fuzzer, writeShellApplication }:

writeShellApplication {
  name = "clamp-smc-charging";
  text = builtins.readFile ./clamp-smc-charging;
  runtimeInputs = [ smc-fuzzer ];
  # pmset
  meta.platforms = [ "aarch64-darwin" ];
}
