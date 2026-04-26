{
  description = "Bazarr distroless image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    bazarrFixed = pkgs.callPackage ./package.nix { };

    packages.${system} = {
      bazarr-image = pkgs.dockerTools.buildLayeredImage {
        name = "bazarr";
        tag = "latest";
        contents = [
          bazarrFixed
          pkgs.dockerTools.caCertificates
          pkgs.tzdata
        ];
        config = {
          ExposedPorts = {
            "6767/tcp" = {};
          };
          Volumes = {
            "/config" = {};
            "/data" = {};
          };

          # Tell Bazarr to use /config as its data directory
          Cmd = [ "${bazarrFixed}/bin/bazarr" "--config" "/config" "--no-update" "True" ];
          # Distroless non‑root user
          User = "1000";
          WorkingDir = "/config";
        };
      };
    };

    # Expose the Sonarr version for CI workflows
    bazarrVersion = bazarrFixed.version;

    defaultPackage.${system} = self.packages.${system}.bazarr-image;
  };
}
