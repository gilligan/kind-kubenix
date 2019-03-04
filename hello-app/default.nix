{ pkgs ? import <nixpkgs> {} }:

with pkgs.stdenv;
with pkgs.lib;

pkgs.yarn2nix.mkYarnPackage {
  name = "hello-app";
  src = ./.;
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
}
