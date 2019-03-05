{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  name = "wait-for-deployment";

  version = "17-12-git";

  src = pkgs.fetchFromGitHub {
    owner = "timoreimann";
    repo = "kubernetes-scripts";
    rev = "a62ef49ea6973a86c82168d3bd8069f887222454";
    sha256 = "0wrdrk816589hikg3knpgk14zv8zwwvh7gmxbrx5prigmr9kskmk";
  };

  deps = pkgs.lib.makeBinPath [
    pkgs.coreutils
    pkgs.kubectl
  ];
  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp wait-for-deployment $out/bin
    chmod +x $out/bin
    wrapProgram $out/bin/wait-for-deployment --prefix PATH : "${deps}"

  '';
}
