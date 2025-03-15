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

          # Create script to initialize a new Slidev project while preserving existing files
          initSlidevScript = pkgs.writeShellScriptBin "init-slidev" ''
            #!/bin/sh
            if [ ! -f "package.json" ]; then
              echo "Initializing Slidev project while preserving existing files..."

              # Create a temporary directory
              TMP_DIR=$(mktemp -d)
              cd "$TMP_DIR"

              # Initialize slidev in the temporary directory
              # Using CI=true to prevent automatic startup
              CI=true npm create slidev@latest -- . --template=default --yes

              # Return to original directory
              cd "$OLDPWD"

              # Copy necessary files without overwriting existing ones
              echo "Copying Slidev files to the current directory..."

              # Copy package.json and package-lock.json
              cp "$TMP_DIR/package.json" .
              [ -f "$TMP_DIR/package-lock.json" ] && cp "$TMP_DIR/package-lock.json" .

              # Copy slides.md only if it doesn't exist
              if [ ! -f "slides.md" ]; then
                cp "$TMP_DIR/slides.md" .
              else
                echo "Keeping existing slides.md"
              fi

              # Copy other necessary directories without overwriting
              mkdir -p components styles
              [ -d "$TMP_DIR/components" ] && cp -rn "$TMP_DIR/components/"* components/ 2>/dev/null || true
              [ -d "$TMP_DIR/styles" ] && cp -rn "$TMP_DIR/styles/"* styles/ 2>/dev/null || true

              # Install dependencies without auto-running scripts
              echo "Installing dependencies..."
              npm install --no-scripts

              # Clean up
              rm -rf "$TMP_DIR"

              echo "Slidev initialized successfully! Run 'slidev' to start the presentation server."
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
                echo "No package.json found. Run 'init-slidev' to create a new Slidev project in this directory."
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
