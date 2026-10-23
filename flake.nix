# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# FA-18 Interceptor website: static landing page + WASM and the downloadable
# ports (Windows, Android, R36S) from the game flake + GitHub Pages. Same
# shape as kurvenrausch.github.io / SuperTux-Origins.github.io.
#
#   nix build          # → result/ (index.html, images/, play/, downloads/)
#   nix run .#serve    # local preview
#
{
  description = "FA-18 Interceptor website (WASM + downloads + GitHub Pages)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # git+https, not github: only a git fetch carries the commit metadata
    # the game flake may use for versioning.
    fa18.url = "git+https://github.com/Grumbel/fa18-interceptor-port";
    fa18.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, fa18 }:
    # x86_64-linux only: the Android SDK/NDK the game's Android build needs
    # are not packaged for other hosts.
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        game = fa18.packages.${system};
        version = game.fa18.version or "0.1.0";

        site = pkgs.runCommand "fa18-site" {
          nativeBuildInputs = [ pkgs.zip ];
        } ''
          mkdir -p $out
          substitute ${./index.html} $out/index.html --subst-var-by version ${version}
          cp -rv ${./images} $out/images

          # Playable WASM build from the game flake (html/js/wasm + index.html).
          mkdir -p $out/play
          cp -rv ${game.fa18-wasm}/. $out/play/
          chmod -R u+w $out/play

          # The ports, built from the same revision, under stable names so
          # the page's links never change (the version is on the page).
          mkdir -p $out/downloads/r36s
          cp -v ${game.fa18-win64-zip}/*.zip $out/downloads/fa18-win64.zip
          cp -v ${game.fa18-win32-zip}/*.zip $out/downloads/fa18-win32.zip
          cp -v ${game.fa18-android}/*.apk $out/downloads/fa18.apk
          # PortMaster expects the zip under the name its port.json gives.
          if [ -f ${game.fa18-r36s-portmaster-zip}/fa18.zip ]; then
            cp -v ${game.fa18-r36s-portmaster-zip}/fa18.zip $out/downloads/r36s/fa18.zip
          else
            cp -v ${game.fa18-r36s-portmaster-zip}/*.zip $out/downloads/r36s/fa18.zip
          fi
          chmod -R u+w $out/downloads

          # Remind visitors that the original ADF is not redistributed.
          cat > $out/downloads/README.txt <<'ADFEOF'
FA-18 Interceptor downloads

These builds do NOT include the original 1988 game disk (ADF).
You must supply your own legal copy of:

  FA-18 Interceptor (1988)(Electronic Arts).adf

- Windows: place the ADF next to fa18.exe (or pass its path as an argument)
- Android: adb push disk.adf into the app files directory
- R36S / PortMaster: place the ADF in the port folder (ports/fa18/)
- Web (play/): use the Upload ADF button on the page
ADFEOF
        '';

        serveApp = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve-fa18-site" ''
            export PKG=${site}
            export PATH=${pkgs.python3}/bin:${pkgs.xdg-utils}/bin:$PATH
            exec bash ${./scripts/serve.sh} "$@"
          '');
          meta.description = "Serve the FA-18 Interceptor site locally and open a browser";
        };
      in
      {
        packages.default = site;
        packages.site = site;

        apps.default = serveApp;
        apps.serve = serveApp;

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.python3 ];
          shellHook = ''
            echo "FA-18 Interceptor website"
            echo "  nix build              # full site → result/"
            echo "  nix run .#serve        # serve + open browser"
            echo "  # against a local game tree:"
            echo "  nix build --override-input fa18 git+file://\$HOME/path/to/fa18-interceptor-port"
          '';
        };
      });
}
