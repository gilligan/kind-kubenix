{ pkgs }:

import (pkgs.fetchFromGitHub {
    owner = "xtruder";
    repo = "kubenix";
    rev = "9acf125f74b9ce7d65b77f33294e65f275b5bc31";
    sha256 = "06z55z4zg8shim3zgkz7j7zkhb9cwm2da9wwh5sf3is7isgyh471";
  }) { inherit pkgs; }
