{ pkgs ? import <nixpkgs> { }, ... }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
let 
  repo = fetchGit {
    url = "https://github.com/overtone1000/REST_Commands.git";
    rev = "a80abf4617c447f3bfa46100760cfb98114a8994";
  };

  manifest = (pkgs.lib.importTOML ("${repo}/core/Cargo.toml")).package;
  lock = ("${repo}/core/Cargo.lock");

  package = pkgs.rustPlatform.buildRustPackage {
    pname = manifest.name;
    version = manifest.version;
    
    src = "${repo}/core";

    #cargoHash = ""; #Determine correct checksum by attempting build and viewing error output
    cargoLock={
      lockFile = (lock);
      allowBuiltinFetchGit = true;
    };
  };
  
  port = 30123;
  dir = "/var";
in
{
  systemd.services.rest_command = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    script = "${package}/bin/${manifest.name} ${port} ${dir}";
    serviceConfig = {
      Restart = "always";
    };
  };
}