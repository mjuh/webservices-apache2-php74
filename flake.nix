{
  description = "Docker container with Apache and PHP builded by Nix";

  inputs.majordomo.url = "git+https://gitlab.intr/_ci/nixpkgs";

  outputs = { self, nixpkgs, majordomo }:
    let
      system = "x86_64-linux";
      pkgs = import majordomo.inputs.nixpkgs {
        overlays = [ majordomo.overlay self.overlay ];
        inherit system;
      };
    in {
      overlay = final: prev: majordomo.packages.${system};

      packages.${system} = {
        container = import ./default.nix { inherit pkgs; };
        deploy = majordomo.outputs.deploy { tag = "webservices/apache2-php74"; };
      };

      checks.${system}.container =
        import ./test.nix { inherit pkgs; };

      defaultPackage.${system} = self.packages.${system}.container;
    };
}
