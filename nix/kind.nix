{ pkgs }:

with pkgs.stdenv.lib;

pkgs.buildGoPackage rec {
  name = "kind-${version}";
  version = "0.1.0-master";

  src = pkgs.fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "kind";
    rev = "91356d6ac460bda3a174850c9b44af7a62924cd3";
    sha256 = "05ssd0gbwz7bz0x05vfjn5agaz5vm546865qafwxwalhr4z3gq0p";
  };

  goPackagePath = "sigs.k8s.io/kind";

  subPackages = ["."];

  #preConfigure = ''
    #export GO111MODULE=on
  #'';

  meta = {
    description = "kubernetes IN Docker - local clusters for testing Kubernetes";
    homepage = https://github.com/kubernetes-sigs/kind;
    maintainers = with maintainers; [ offline rawkode ];
    license = stdenv.lib.licenses.asl20;
    platforms = platforms.unix;
  };
}
