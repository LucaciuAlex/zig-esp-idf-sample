{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    esp-idf.url = "github:mirrexagon/nixpkgs-esp-dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      esp-idf,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            esp-idf.overlays.default
          ];
        };

        # Determine architecture-specific properties
        platformSrc =
          if system == "x86_64-linux" then
            {
              url = "https://github.com/kassane/zig-espressif-bootstrap/releases/download/0.17.0-xtensa/zig-relsafe-x86_64-linux-musl-baseline.tar.xz";
              sha256 = "sha256-rrBOw7CRwEDdYgH5I8P3ea4TwGyVVrPYpXH0ibviMDE=";
            }
          else if system == "aarch64-linux" then
            {
              url = "https://github.com/kassane/zig-espressif-bootstrap/releases/download/0.17.0-xtensa/zig-relsafe-aarch64-linux-musl-baseline.tar.xz";
              sha256 = "sha256-yvKVaH0W0c+TnXCfrq/FbEmfZzU5S69C8YfqPqHbfG4=";
            }
          else if system == "aarch64-darwin" then
            {
              url = "https://github.com/kassane/zig-espressif-bootstrap/releases/download/0.17.0-xtensa/zig-relsafe-aarch64-macos-baseline.tar.xz";
              sha256 = "sha256-rTiRBqlU2rpFJ/bRdr6rFwSLECTyZLN63CEAP7XjHWU=";
            }
          else
            throw "Unsupported platform: ${system}";

        zlsSrc =
          if system == "x86_64-linux" then
            {
              url = "https://github.com/zigtools/zls/releases/download/0.17.0/zls-x86_64-linux.tar.xz";
              sha256 = "dfa4514e1868803fdf2ae56832c88b9d400094d70ea6bb136b57bcc91af10258";
            }
          else if system == "aarch64-linux" then
            {
              url = "https://github.com/zigtools/zls/releases/download/0.17.0/zls-aarch64-linux.tar.xz";
              sha256 = "0d314f3cab30da770328e1b8c84ab89bb308e56dbc26a85ac82429ff02b44873";
            }
          else if system == "aarch64-darwin" then
            {
              url = "https://github.com/zigtools/zls/releases/download/0.17.0/zls-aarch64-macos.tar.xz";
              sha256 = "2e451358b4f7e2d4b1fccb65db177dbb321c5a98e95f67e09aa72d6ecfb39d20";
            }
          else
            throw "Unsupported platform: ${system}";

        zlsRelease = pkgs.stdenv.mkDerivation {
          pname = "zls";
          version = "0.17.0";
          src = pkgs.fetchurl zlsSrc;
          nativeBuildInputs = [
            pkgs.gnutar
            pkgs.xz
          ];
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            tar -xJf $src -C $out/bin
            chmod +x $out/bin/zls
          '';
        };

      in
      with pkgs;
      {
        formatter = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
        devShells.default = mkShell {
          buildInputs = [
            bashInteractive

            (pkgs.stdenv.mkDerivation {
              pname = "zig-espressif-bootstrap";
              version = "0.17.0-xtensa";
              src = pkgs.fetchurl platformSrc;
              dontConfigure = true;
              dontBuild = true;
              dontFixup = true;
              installPhase = ''
                mkdir -p $out/{doc,bin,lib}
                cp -r doc/* $out/doc
                cp -r lib/* $out/lib
                cp zig $out/bin/zig
              '';
            })

            zlsRelease

            esp-idf-full
          ];
        };
      }
    );
}
