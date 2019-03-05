{ kind, pkgs }:

pkgs.writeScriptBin "test-deployment" ''
      #! ${pkgs.runtimeShell}
      set -euo pipefail
      SERVICE_URL=http://localhost:8001/api/v1/namespaces/default/services/hello:3000/proxy/
      KUBECONFIG=$(${kind}/bin/kind get kubeconfig-path --name="kind")

      PROXY_PID=""
      trap cleanup EXIT

      function cleanup {
        if ! [ -z $PROXY_PID ]; then
          kill -9 $PROXY_PID
        fi
      }

      CLUSTERS=$(${kind}/bin/kind get clusters)
      if ! [ "$CLUSTERS" = "kind" ]; then
        echo "Error: kind cluster not running"
        exit 1
      fi

      echo "- Cluster seems to be up and running ✓"

      ${pkgs.kubectl}/bin/kubectl proxy >/dev/null &
      PROXY_PID=$!
      sleep 3

      RESPONSE=$(${pkgs.curl}/bin/curl --silent $SERVICE_URL)
      if ! [ "$RESPONSE" == "Hello World" ]; then
        echo "Error: did not get expected response from service:"
        echo $RESPONSE
        exit 1
      fi

      echo "- Service returns expected response ✓"
    ''
