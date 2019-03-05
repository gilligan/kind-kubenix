{ pkgs ? import <nixpkgs> {} }:

let

  kind = pkgs.callPackage ./nix/kind.nix {};

  helloApp = pkgs.callPackage ./hello-app {};

  kubenix = pkgs.callPackage ./nix/kubenix.nix {};

  wait-for-deployment = pkgs.callPackage ./nix/wait-for-deployment.nix {};

  buildConfig = t: kubenix.buildResources { configuration = import ./configuration.nix { type = t; }; };

  appImage = pkgs.dockerTools.buildLayeredImage {
    name = "hello-app";
    tag = "latest";
    config.Cmd = [ "${helloApp}/bin/hello-app" ];
  };

in

  rec {

    app = helloApp;

    test-deployment = pkgs.callPackage ./nix/test-deployment.nix { 
      inherit kind; 
    };

    deploy-to-kind = pkgs.callPackage ./nix/deploy-to-kind.nix { 
      config = buildConfig "dev";
      inherit kind; 
      inherit appImage; 
    };

    shell = pkgs.mkShell {
      buildInputs = [ 
        kind
        deploy-to-kind
        test-deployment
        wait-for-deployment
        pkgs.curl
        pkgs.docker 
        pkgs.kubectl
      ];
    };

  }
