{
  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable"; };
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems, ... }@inputs:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems) (system:
          f (import nixpkgs {
            inherit system;
            config = { allowUnfree = true; };
            overlays = [ ];
          }));

      # Helper to fetch model
      getModel = pkgs: pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
        sha256 = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4="; # Placeholder, nix will fail with correct hash if wrong
      };
    in {
      packages = eachSystem (pkgs: {
        default = pkgs.writeShellScriptBin "murmur" ''
          export MURMUR_MODEL_PATH="${getModel pkgs}"
          export PATH="${pkgs.alsa-utils}/bin:${pkgs.whisper-cpp}/bin:${pkgs.xclip}/bin:$PATH"
          ${self.packages.${pkgs.system}.murmur-binary}/bin/murmur
        '';

        murmur-binary = pkgs.buildGoModule {
          pname = "murmur";
          version = "0.1.0";
          src = ./.;
          vendorHash = "sha256-J2xl++Qljg4iX6UdENWl/nDxbozdLuq2IkJYdyTSLnQ=";
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [
            pkgs.gtk3
            pkgs.libayatana-appindicator
          ];
        };
      });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          hardeningDisable = [ "all" ];
          buildInputs = [
            pkgs.pkg-config
            pkgs.gtk3
            pkgs.libayatana-appindicator
            pkgs.alsa-utils
            pkgs.xclip
          ];

          packages = [
            pkgs.delve
            pkgs.gcc
            pkgs.gh
            pkgs.go_1_26
            pkgs.gotools
            pkgs.gopls
            pkgs.go-outline
            pkgs.gopkgs
            pkgs.godef
            pkgs.golangci-lint
            pkgs.go-tools
            pkgs.treefmt
            pkgs.whisper-cpp
          ];
        };
      });
    };
}
