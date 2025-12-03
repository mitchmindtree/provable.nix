{
  description = "A flake for the Leo language.";

  inputs = {
    leo-src = {
      url = "github:provablehq/leo";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    let
      overlays = [
        inputs.rust-overlay.overlays.default
        inputs.self.overlays.default
      ];
      perSystemPkgs =
        f:
        inputs.nixpkgs.lib.genAttrs (import inputs.systems) (
          system: f (import inputs.nixpkgs { inherit overlays system; })
        );
    in
    {
      overlays = {
        default =
          final: prev:
          let
            # Provide versions of leo built with both the officially supported
            # rust version, as well as a rust nightly compiler to allow
            # build-time profiling.
            rust = prev.rust-bin.fromRustupToolchainFile "${inputs.leo-src}/rust-toolchain.toml";
            rust-nightly = prev.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
          in
          {
            # Stable, official leo.
            leo = prev.callPackage ./pkgs/leo.nix {
              src = inputs.leo-src;
              rust = rust;
            };

            # Leo built with nightly rust.
            leo-rust-nightly = prev.callPackage ./pkgs/leo.nix {
              src = inputs.leo-src;
              rust = rust-nightly;
            };
          };
      };

      packages = perSystemPkgs (pkgs: {
        leo = pkgs.leo;
        leo-rust-nightly = pkgs.leo-rust-nightly;
        default = pkgs.leo;
      });

      devShells = perSystemPkgs (pkgs: {
        leo-dev = pkgs.callPackage ./pkgs/leo-dev.nix { };
        leo-nightly-dev = pkgs.callPackage ./pkgs/leo-dev.nix { leo = pkgs.leo-rust-nightly; };
        default = inputs.self.devShells.${pkgs.stdenv.hostPlatform.system}.leo-dev;
      });

      formatter = perSystemPkgs (pkgs: pkgs.nixfmt-tree);
    };
}
