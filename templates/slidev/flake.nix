# SPDX-FileCopyrightText: 2021-2025 Akira Komamura
# SPDX-License-Identifier: Unlicense
{
  description = "Slidev presentation with Playwright PDF export support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Create script to initialize a new Slidev project
          initSlidevScript = pkgs.writeShellScriptBin "init-slidev" ''
            #!/bin/sh
            if [ ! -f "package.json" ]; then
              echo "Initializing new Slidev project..."
              npm create slidev@latest
            else
              echo "Project already initialized. Run 'npm install' if needed."
            fi
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nodejs

              # Use corepack to install npm/pnpm/yarn as specified in package.json
              pkgs.corepack

              # Required to enable the language server
              pkgs.nodePackages.typescript
              pkgs.nodePackages.typescript-language-server

              # Add our scripts to the shell
              initSlidevScript
            ];

            shellHook = ''
              # Add node_modules/.bin to PATH to make local CLIs available
              export PATH="$PWD/node_modules/.bin:$PATH"

              if [ ! -f "package.json" ]; then
                echo "No package.json found. Run 'init-slidev' to create a new Slidev project."
              else
                echo "Local node_modules/.bin added to PATH. You can run 'slidev' directly."
              fi

            '';
          };

          export = pkgs.mkShell {
            packages = [
              pkgs.nodejs
              pkgs.corepack
              pkgs.nodePackages.typescript
              pkgs.nodePackages.typescript-language-server
              # For Playwright
              # pkgs.playwright-driver
              # pkgs.playwright-driver.browsers

              # System dependencies for Playwright
              # pkgs.xvfb-run
              # pkgs.chromium
#
              # # Additional dependencies that may be needed
              # pkgs.atk
              # pkgs.glib
              # pkgs.gtk3
              # pkgs.cairo
              # pkgs.pango
              # pkgs.freetype
              # pkgs.fontconfig
              # pkgs.dbus
              # pkgs.nss
              # pkgs.nspr
              # pkgs.expat
              # pkgs.cups
              #
              # # jq for parsing browser revision info
              # pkgs.jq
            ];

            shellHook = ''
              # Add node_modules/.bin to PATH to make local CLIs available
              export PATH="$PWD/node_modules/.bin:$PATH"

              # # Ensure the browser environment variables are correctly set
              # export PLAYWRIGHT_NODEJS_PATH="${pkgs.nodejs}/bin/node"
              # export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH="${pkgs.chromium}/bin/chromium"
              # export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
              # export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
#
              # playwright_chromium_revision="$(jq --raw-output '.browsers[] | select(.name == "chromium").revision' ${pkgs.playwright-driver}/package/browsers.json)"
              # export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="${pkgs.playwright-driver.browsers}/chromium-$playwright_chromium_revision/chrome-linux/chrome";
              # echo "Playwright environment ready with browser at $PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH"
            '';
          };
        });
    };
}
