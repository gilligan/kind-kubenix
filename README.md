## Playing With Kubernetes: Nix, Kind And Kubenix

This little playground aims to illustrate how you can use [kubenix](https://github.com/xtruder/kubenix) and
[kind](https://github.com/kubernetes-sigs/kind) for testing kubernetes configurations locally in a completely portable manner.

### A service to deploy: hello

The service itself is mostly irrelevant for our purposes so we just write a little express based JavaScript app that
returns "Hello World" on a port that can be configured via the environment variable `APP_PORT`:

```js
#!/usr/bin/env node

const express = require('express');
const app = express();
const port = process.env.APP_PORT ? process.env.APP_PORT : 3000;


app.get('/', (req, res) => res.send('Hello World'));
app.listen(port, () => console.log(`Listening on port ${port}`));

```
#### Can we nixify this please? Yes we can!

In order to nixify our little [hello-app](./hello-app/index.js) we are going to use
[yarn2nix](https://github.com/moretea/yarn2nix) which makes everything really for us:

```nix
pkgs.yarn2nix.mkYarnPackage {
  name = "hello-app";
  src = ./.;
  packageJson = ./package.json;
  yarnLock = ./yarn.lock;
}
```

We just have to make sure that we add `"bin": "index.js"` to our `package.json` and `mkYarnPackage` will put
`index.js` in the `bin` path of our output. Since we added `#!/usr/bin/env node` to `index.js`, node will also be
added to closure of our app derivation.

#### Creating a docker image of our app

Next we want to create a docker image of our app using [`dockerTools.buildLayeredImage`](https://nixos.org/nixpkgs/manual/#ssec-pkgs-dockerTools-buildLayeredImage):

```nix
  pkgs.dockerTools.buildLayeredImage {
    name = "hello-app";
    tag = "latest";
    config.Cmd = [ "${helloApp}/bin/hello-app" ];
  }
```
`${helloApp}` is of course the derivation we created above using `mkYarnPackage`. Easy as pie.

### Cluster in a box: kind

kind is a portable (linux, osx and windows) solution to running kubernetes clusters locally, in a docker container. The project
is still young but it is getting a lot of support and works very well already:

```
$ kind create cluster
Creating cluster 'kind-1' ...
 ✓ Ensuring node image (kindest/node:v1.13.2) 🖼
 ✓ [control-plane] Creating node container 📦
 ✓ [control-plane] Fixing mounts 🗻
 ✓ [control-plane] Starting systemd 🖥
 ✓ [control-plane] Waiting for docker to be ready 🐋
 ✓ [control-plane] Pre-loading images 🐋
 ✓ [control-plane] Creating the kubeadm config file ⛵
 ✓ [control-plane] Starting Kubernetes (this may take a minute) ☸
Cluster creation complete. You can now use the cluster with:

export KUBECONFIG="$(kind get kubeconfig-path --name="1")"
kubectl cluster-info
$ export KUBECONFIG="$(kind get kubeconfig-path --name="1")"

$ kubectl cluster-info
Kubernetes master is running at https://localhost:46489
KubeDNS is running at https://localhost:46489/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

All it takes is `kind create cluster` and setting the correct KUBECONFIG environment variable and we can interact with the
cluster via `kubectl`


### kubenix: validation for free and no yaml in sight either

The [kubenix](https://github.com/xtruder/kubenix) parses a kubernetes configuration in Nix
and validates it against the official swagger specification of the designated kubernetes version. Apart from getting a compile-time validation for free, writing kubernetes configurations in Nix
allows for much better abstraction and less redundancy which otherwise creeps in all to easy.

For the most part the [configuration.nix](./configuration.nix) is analogous to what would otherwise
be written in YAML or JSON. Yet `configuration.nix` actually defines a function:

```nix
{ type ? "dev" }:

let
  kubeVersion = "1.11";
  helloAppPort = 3000;
  helloCpu = if type == "dev" then "100m" else "1000m";
in
{
  kubernetes.version = kubeVersion;

  kubernetes.resources.deployments.hello = {
  # ...
  };
  # ...
}
```

The function accepts a `type` argument which defines if we want a development configuration or
not. Below we set some variables accordingly - Obviously just a motivating example. It would also
be possible to have a `generic.nix` configuration wich is extended with `production.nix` or `dev.nix` -- the sky is the limit. Think about the requirements of your project and design accordingly.
For this project a valid kubernetes json configuration is created using kubenix as follows:

```nix
buildConfig = t: kubenix.buildResources { configuration = import ./configuration.nix { type = t; }; };

```


### Applying our configuration

kubenix gives us a validated k8s configuration (try to add some nonesense and you will see that
it will actually yell at you) and with kind we can pull up a k8s cluster without any effort.
Time to throw the configuration at the cluster. [deploy-to-kind](./nix/deploy-to-kind.nix) does
just that. There is one small detour that we have to take in there:

Remember our little hello service that we dockerized? Ideally we don't want to push that to
the docker hub just for testing it in our kind cluster. In order to achieve that we just need
to make sure that ..

1. kubernetes doesn't try to pull it: [configuration.nix](./configuration.nix#L21)
2. the image is available to the docker daemon running in the kind container: [nix/deploy-to-kind.nix](nix/deploy-to-kind.nix#13)

With that out of the way we can just use `kubectl` to apply our config.


### Finishing Up

The project provides a shell in which two scripts are made available:

- `deploy-to-kind`: create a kind cluster and apply the configuration to it
- `test-deployment`: A very simplistic smoke test to check if our app is running

Of course none of this is production ready but hopefully it was useful to illustrate how you could indeed
make use of kubenix and kind to quickly validate the kubernetes configuration you are working on locally, across
different platforms.
