{
  description = "Freelock template flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Import the drupal-flake repository to use as a template
    drupal-flake = {
      url = "github:freelock/drupal-flake";
      flake = true;
    };
  };

  outputs = { self, nixpkgs, drupal-flake }: {
    templates = {
      # Default template points to slidev for backward compatibility
      default = self.templates.slidev;

      # Slidev-specific template
      slidev = {
        path = ./templates/slidev;  # Points to the slidev template directory
        description = "Bootstrap a new Slidev presentation with Playwright support";
        welcomeText = ''
          # Slidev Project Template

          Your Slidev project has been initialized!

          ## Getting Started

          Run the following commands:

          ```bash
          # Enter development shell
          nix develop

          # Initialize Slidev if not already initialized
          init-slidev

          # Start Slidev development server
          slidev

          # Export slides to PDF
          slidev-export
          ```

          Edit your slides in the `slides.md` file.
        '';
      };

      # Drupal template - reference the imported flake
      drupal = {
        path = drupal-flake.outPath;
        description = "Bootstrap a new Drupal project using Freelock's Drupal flake";
        welcomeText = ''
          # Drupal Project Template

          Your Drupal project has been initialized using freelock/drupal-flake!

          ## Getting Started

          ```bash
          # Enter development shell
          nix develop

          # Start local development environment
          ddev start
          ```

          Check the README.md for more detailed instructions.
        '';
      };
    };
  };
}
