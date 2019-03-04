{ pkgs ? import <nixpkgs> {} }:

let
  kind = pkgs.callPackage ./nix/kind.nix {};

  helloApp = pkgs.callPackage ./hello-app {};

  kubenix = pkgs.callPackage ./nix/kubenix.nix {};

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

    test-deployment = pkgs.writeScriptBin "test-deployment" ''
      #! ${pkgs.runtimeShell}
      set -e

      PROXY_PID=""
      trap cleanup EXIT

      function cleanup {
        if ! [ -z $PROXY_PID ]; then
          kill -9 $PROXY_PID
        fi
      }

      CLUSTERS=$(${kind}/bin/kind get clusters)
      if ! [ "$CLUSTERS" = "1" ]; then
        echo "Error: kind cluster not running"
        exit 1
      fi

      echo "- Cluster seems to be up and running ✓"

      ${pkgs.kubectl}/bin/kubectl proxy >/dev/null &
      PROXY_PID=$!
      sleep 3

      RESPONSE=$(${pkgs.curl}/bin/curl --silent http://localhost:8001/api/v1/namespaces/default/services/hello:3000/proxy/)
      if ! [ "$RESPONSE" == "Hello World" ]; then
        echo "Error: did not get expected response from service:"
        echo $RESPONSE
        exit 1
      fi

      echo "- Service returns expected response ✓"
    '';
    deploy-to-kind = pkgs.writeScriptBin "deploy-to-kind" ''
      #! ${pkgs.runtimeShell}
      set -e
      ${kind}/bin/kind delete cluster
      ${kind}/bin/kind create cluster

      echo "Loading the docker image inside the kind docker container ..."
      export KUBECONFIG=$(${kind}/bin/kind get kubeconfig-path --name="1")
      KIND_CONTAINER=$(${pkgs.docker}/bin/docker container ls | ${pkgs.gnugrep}/bin/grep kind-1-control-plane | ${pkgs.gawk}/bin/awk '{print $1}')
      cat ${appImage} | ${pkgs.docker}/bin/docker exec -i $KIND_CONTAINER sh -c "cat | docker load"

      echo "Applying the configuration ..."
      cat ${devConfig} | ${pkgs.jq}/bin/jq "."
      cat ${devConfig} | ${pkgs.kubectl}/bin/kubectl apply -f -

      echo "Set KUBECONFIG as follows to use kubectl with the kind cluster:"
      echo ""
      echo "export KUBECONFIG=$(kind get kubeconfig-path --name=\"1\")"
      echo ""
    '';
    shell = pkgs.mkShell {
      buildInputs = [ deploy-to-kind test-deployment ];
    };
  }
