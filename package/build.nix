{ pkgs ? import <nixpkgs> { } }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rest_commands";
  version = "0.1";
  src = pkgs.lib.cleanSource ../core/.;
  cargoLock={
    lockFile = ../core/Cargo.lock;
    allowBuiltinFetchGit = true;
  };
}