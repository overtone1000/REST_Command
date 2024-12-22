{ pkgs ? import <nixpkgs> { } }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "rest_commands";
  version = "0.1";
  src = pkgs.lib.cleanSource ../core/.;
  cargoLock={
    lockFile = ../core/Cargo.lock;
  };
}