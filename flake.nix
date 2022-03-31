{
  description = "Docker container with Apache and PHP builded by Nix";

  inputs.majordomo.url = "git+https://gitlab.intr/_ci/nixpkgs";

  outputs = { self, nixpkgs, majordomo }:
    let system = "x86_64-linux";
    in {
      packages.${system} = {
        container = import ./default.nix { pkgs = majordomo.outputs.nixpkgs; };
        deploy =
          majordomo.outputs.deploy { tag = "webservices/apache2-php74"; };
      };

      defaultPackage.${system} = self.packages.${system}.container;

      checks.${system} = {
        container = import ./test.nix { pkgs = majordomo.outputs.nixpkgs; };
      };
    };
}
