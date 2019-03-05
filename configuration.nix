{ type ? "dev" }:

let
  kubeVersion = "1.11";

  helloApp = rec {
    label = "hello";
    port = 3000;
    cpu = if type == "dev" then "100m" else "1000m";
    imagePolicy = if type == "dev" then "Never" else "IfNotPresent";
    env = [{ name = "APP_PORT"; value = "${toString port}"; }];
  };
in
{
  kubernetes.version = kubeVersion;

  kubernetes.resources.deployments."${helloApp.label}" = {
    metadata.labels.app = helloApp.label;
    spec = {
      replicas = 1;
      selector.matchLabels.app = helloApp.label;
      template = {
        metadata.labels.app = helloApp.label;
        spec.containers."${helloApp.label}" = {
          name = "${helloApp.label}";
          image = "hello-app:latest";
          imagePullPolicy = helloApp.imagePolicy;
          env = helloApp.env;
          resources.requests.cpu = helloApp.cpu;
          ports."${toString helloApp.port}" = {};
        };
      };
    };
  };

  kubernetes.resources.services."${helloApp.label}" = {
    spec.selector.app = "${helloApp.label}";
    spec.ports."${toString helloApp.port}".targetPort = helloApp.port;
  };
}
