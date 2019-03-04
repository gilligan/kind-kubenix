{ kind, pkgs }:

pkgs.writeScriptBin "test-deployment" ''
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
    ''
