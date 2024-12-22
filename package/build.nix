{ pkgs ? import <nixpkgs> { } }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "rest_commands";
  version = "0.1";
  cargoLock.lockFile = ./core/Cargo.lock;
  src = pkgs.lib.cleanSource ./core/.;
}