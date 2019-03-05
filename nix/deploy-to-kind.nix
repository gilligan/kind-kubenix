{ kind, appImage, config, pkgs }:

pkgs.writeScriptBin "deploy-to-kind"
''
      #! ${pkgs.runtimeShell}
      set -e
      ${kind}/bin/kind delete cluster || true
      ${kind}/bin/kind create cluster

      echo "Loading the ${pkgs.docker}/bin/docker image inside the kind docker container ..."
      export KUBECONFIG=$(${kind}/bin/kind get kubeconfig-path --name="kind")
      KIND_CONTAINER=$(${pkgs.docker}/bin/docker container ls | ${pkgs.gnugrep}/bin/grep kind-control-plane | ${pkgs.gawk}/bin/awk '{print $1}')
      cat ${appImage} | ${pkgs.docker}/bin/docker exec -i $KIND_CONTAINER sh -c "cat | docker load"

      echo "Applying the configuration ..."
      cat ${config} | ${pkgs.jq}/bin/jq "."
      cat ${config} | ${pkgs.kubectl}/bin/kubectl apply -f -
''
