{ pkgs ? import <nixpkgs> { }, port ? 30123, dir ? "/var", path ? [ pkgs.echo ], hyper_hash ? pkgs.lib.fakeHash, ... }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
#This requires git installed systemwide in environment.systemPackages. Build the system to install git, then rebuild to install this config.
let 
  repo = fetchGit {
    url = "https://github.com/overtone1000/REST_Commands.git";
    ref = "main"; #this does seem to be necessary
    #shallow = true;
    rev = "4ebf990e1bedd27464f033f5dfd046a1ec610e43"; #sometimes need to force it to rebuild
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
      #outputHashes = { #Not needed with allowBuiltinFetchGet
      #   "hyper-services-0.1.0" = hyper_hash;
      #};
    };
  };
in
{
  systemd.services.rest_command = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    script = "${package}/bin/${manifest.name} ${port} ${dir}";
    path = path;
    serviceConfig = {
      User = "root";
      Restart = "always";
    };
  };
}