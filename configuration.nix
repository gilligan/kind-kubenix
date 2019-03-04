{ type ? "dev" }:

let
  kubeVersion = "1.11";
  helloAppPort = 3000;
  helloCpu = if type == "dev" then "100m" else "1000m";
in
{
  kubernetes.version = kubeVersion;

  kubernetes.resources.deployments.hello = {
    metadata.labels.app = "hello";
    spec = {
      replicas = 1;
      selector.matchLabels.app = "hello";
      template = {
        metadata.labels.app = "hello";
        spec.containers.hello = {
          name = "hello";
          image = "hello-app:latest";
          imagePullPolicy = "Never";
          ports."${toString helloAppPort}" = {};
          resources.requests.cpu = "100m";
          env = [
            { name = "APP_PORT"; value = "${toString helloAppPort}"; }
          ];
        };
      };
    };
  };

  kubernetes.resources.services.hello = {
    spec.selector.app = "hello";
    spec.ports."${toString helloAppPort}".targetPort = helloAppPort;
  };
}
