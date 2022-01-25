{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, flake-utils, naersk }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = naersk.lib."${system}";
        nativeBuildInputs = with pkgs; [ pkg-config openssl ];
      in
        rec {
          # `nix build`
          packages.foundry = naersk-lib.buildPackage {
            pname = "foundry";
            root = ./.;

            copySources = ["ui"]; # https://github.com/nix-community/naersk/issues/133
            #singleStep = true;

            inherit nativeBuildInputs;
            # FIXME: Still doesn't build properly
          };
          defaultPackage = packages.foundry;

          # `nix run`
          apps.foundry = flake-utils.lib.mkApp {
            drv = packages.foundry;
          };
          defaultApp = apps.foundry;

          # `nix develop`
          devShell = pkgs.mkShell {
            buildInputs = with pkgs;[ cargo rust-analyzer rustc rustfmt rustPackages.clippy ];

            # Convenience indicator for when we're inside the shell env
            shellHook = ''
              export PS1="\e[01;33m\][foundry]\e[01;34m\] \w $ \e[m\]"
            '';

            inherit nativeBuildInputs;
          };
        }
    );
}
