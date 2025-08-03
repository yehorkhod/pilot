{
  description = "Pilot sessions";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      name = "pilot";
      system = "x86_64-linux";
      pkgs = nixpkgs { inherit system; };
    in {
      packages.${system}.${name} = pkgs.stdenv.mkDerivation {
        pname = name;
        version = "1.0.0";
        src = self;
        buildInputs = [ pkgs.fzf pkgs.tmux ];
        installPhase = ''
          mkdir -p $out/bin
          cp pilot $out/bin/pilot
        '';

      };
      defaultPackage.${system} = self.packages.${system}.${name};
    };
}
