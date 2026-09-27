# default.nix
with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "dev-environment"; # Probably put a more meaningful name here
    buildInputs = [ 
        pkg-config  

        #Backend
        #From nixos.wiki/wiki/Rust
        rustc
        cargo
        gcc
        rustfmt
        clippy 
    ];
}

