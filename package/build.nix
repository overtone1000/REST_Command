{ pkgs ? import <nixpkgs> { } }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
let 
  toml = ../core/Cargo.toml;
  lock = ../core/Cargo.lock;
  src_dir = ../core/.;
  manifest = (pkgs.lib.importTOML (toml)).package;

in

pkgs.rustPlatform.buildRustPackage rec {
  pname = manifest.name;
  version = manifest.version;
  src = pkgs.lib.cleanSource (src_dir);
  cargoLock={
    lockFile = (lock);
    allowBuiltinFetchGit = true;
  };
}