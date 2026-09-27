{ pkgs ? import <nixpkgs> { }, port ? 30123, dir ? "/var", path ? [ pkgs.echo ], hyper_hash ? pkgs.lib.fakeHash, ... }:
#Ensure nixpkgs is up to date. Check the channel currently used with sudo nix-channel --list (it's the one named nixos) and the rustc version with rustc -V
#This requires git installed systemwide in environment.systemPackages. Build the system to install git, then rebuild to install this config.
let 
  repo = fetchGit {
    url = "https://github.com/overtone1000/REST_Commands.git";
    ref = "main"; #this does seem to be necessary
    # shallow = true; #Seems this may be what was stopping updates with "rev"
    rev = "b5702a4d890d019f7c80cec174730c396c8d6442"; #sometimes need to force it to pull in latest rev, so update here; don't forget that cargo.lock in this version will also be used!
  };

  manifest = (pkgs.lib.importTOML ("${repo}/Cargo.toml")).package;
  lock = ("${repo}/Cargo.lock");

  package = pkgs.rustPlatform.buildRustPackage {
    pname = manifest.name;
    version = manifest.version;
    
    src = "${repo}";
    cargoBuildFlags= [ "-p" "core" ]; #Target the core package
    
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