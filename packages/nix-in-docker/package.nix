{ writeShellApplication }:

writeShellApplication {
  name = "nix-in-docker";
  text = builtins.readFile ./nix-in-docker.sh;
  meta = {
    homepage = "https://discourse.nixos.org/t/build-x86-64-linux-on-aarch64-darwin/35937/2";
  };
}
