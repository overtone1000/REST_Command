{ pkgs ? import <nixpkgs> { } }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
let 
  repo = fetchGit {
    url = "https://github.com/overtone1000/REST_Commands.git";
    rev = "c7fb4e8bbfd4bc84be4ffcccc94bdafa7ff8882a";
  };

  manifest = (pkgs.lib.importTOML ("${repo}/core/Cargo.toml")).package;
  lock = ("${repo}/core/Cargo.lock");
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = manifest.name;
  version = manifest.version;
  
  src = "${repo}/core";

  #cargoHash = ""; #Determine correct checksum by attempting build and viewing error output
  cargoLock={
    lockFile = (lock);
    allowBuiltinFetchGit = true;
  };
}