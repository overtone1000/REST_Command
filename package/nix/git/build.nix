{ pkgs ? import <nixpkgs> { }, port ? 30123, dir ? "/var", path ? [ pkgs.echo ], hyper_hash ? pkgs.lib.fakeHash, ... }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
#This requires git installed systemwide in environment.systemPackages. Build the system to install git, then rebuild to install this config.
let 
  repo = fetchGit {
    url = "https://github.com/overtone1000/REST_Commands.git";
    ref = "main"; #this does seem to be necessary
    shallow = true;
    #rev = "dd5a804ac73edf0590d936699b97e0b8629d30a3"; #sometimes need to force it to pull in latest rev, so update here
  };

  manifest = (pkgs.lib.importTOML ("${repo}/Cargo.toml")).package; #Use the one in repo root, not the core subdirectory!
  lock = ("${repo}/Cargo.lock"); #Need the repo root lock!!

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
    wants = [ "network-online.target" ]; #For health checkin
    script = "${package}/bin/${manifest.name} ${port} ${dir}";
    path = path;
    serviceConfig = {
      User = "root";
      Restart = "always";
    };
  };
}