{ pkgs ? import <nixpkgs> {} }:

let
  kind = pkgs.callPackage ./kind.nix {};

  helloApp = pkgs.callPackage ./hello-app {};

  kubenix = pkgs.callPackage ./kubenix.nix {};

  buildConfig = t: kubenix.buildResources { configuration = import ./configuration.nix { type = t; }; };

  appImage = pkgs.dockerTools.buildLayeredImage {
    name = "hello-app";
    tag = "latest";
    config.Cmd = [ "${helloApp}/bin/hello-app" ];
  };
in
  rec {
    app = helloApp;
    devConfig = buildConfig "dev";
    prodConfig = buildConfig "prod";
    shell = pkgs.mkShell {
      buildInputs = [ kind pkgs.jq pkgs.kubectl ];
      shellHook = ''
        kind delete cluster
        kind create cluster

        export KUBECONFIG=$(kind get kubeconfig-path --name="1")
        KIND_CONTAINER=$(docker container ls | grep kind-1-control-plane | awk '{print $1}')
        cat ${appImage} | docker exec -i $KIND_CONTAINER sh -c "cat | docker load"

        echo "Applying the following config to k8s:"
        cat ${devConfig} | jq "."
        cat ${devConfig} | kubectl apply -f -
      '';
    };
  }
