#!/bin/bash

cd ../core || exit
nix --extra-experimental-features nix-command build -f ../package/build.nix