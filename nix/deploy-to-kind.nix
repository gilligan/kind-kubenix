{ kind, appImage, config, pkgs }:

pkgs.writeScriptBin "deploy-to-kind"
''
      #! ${pkgs.runtimeShell}
      set -e
      ${kind}/bin/kind delete cluster || true
      ${kind}/bin/kind create cluster

      echo "Loading the ${pkgs.docker}/bin/docker image inside the kind docker container ..."
      export KUBECONFIG=$(${kind}/bin/kind get kubeconfig-path --name="kind")

      kind load image-archive ${appImage}

      echo "Applying the configuration ..."
      cat ${config} | ${pkgs.jq}/bin/jq "."
      cat ${config} | ${pkgs.kubectl}/bin/kubectl apply -f -
''
