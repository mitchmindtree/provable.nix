{
  makeRustPlatform,
  openssl,
  pkg-config,
  rust,
  src,
}:
let
  rustPlatform = makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };
  manifestPath = "${src}/Cargo.toml";
  manifest = builtins.fromTOML (builtins.readFile manifestPath);
in
rustPlatform.buildRustPackage {
  pname = "leo";
  version = manifest.package.version;
  src = src;
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "snarkvm-4.4.0" = "sha256-M6ttcW1r5K33dCZDrx0y22bAlPRIsF3uNJOgcGHFIUc=";
    };
  };
  nativeBuildInputs = [
    pkg-config
  ];
  buildInputs = [
    openssl
  ];
  doCheck = false; # Tested in CI.
}
