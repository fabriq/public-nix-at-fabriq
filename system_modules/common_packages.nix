{ config, lib, pkgs, pkgsUnstable, ... }:

with lib;

let
  cfg = config.fabriq.commonPackages;
in

{
  options.fabriq.commonPackages = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to install packages commonly used at Fabriq.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      # Nix tooling
      pkgs.nil # Nix language server
      pkgs.nixpkgs-fmt # A Nix formatter

      # Common CLI programs
      pkgs.coreutils # Core Unix utilities
      pkgs.moreutils # More of them
      pkgs.findutils # find, locate and xargs
      pkgs.inetutils # ifconfig, ping and other network utils
      pkgs.gnugrep # GNU version of grep; more featureful than macOS'version
      pkgs.gnused # GNU version of sed; more featureful than macOS'version
      pkgs.curl # Universal program to make L7 requests
      pkgs.vim # Universal CLI editor
      pkgs.less # Universal pager

      # Version control
      pkgs.git
      pkgs.mob # Makes pair/ensemble programming easier with git

      # Utilities
      pkgs.ripgrep # Faster, friendlier grep
      pkgs.tokei # Stats on lines of codes
      pkgs.awscli2 # AWS CLI
      pkgs.jq # Work on JSON from the CLI
      pkgs.imagemagick # Image processing
      pkgs.ffmpeg # Video processing
      pkgs.htop # Activity monitor in the terminal
      pkgs.graphviz # Print graphs

      # Project dependencies
      # (We'll put them in their respective repositories once we support it)
      pkgsUnstable.deno # For the new stack
      pkgs.poetry # For Django
      pkgs.python39Full # For Django
      pkgs.nodejs-18_x # For Webapp
      pkgs.terraform # For Terraform
      pkgs.packer # For Packer
    ];

    environment.variables = {
      # Configure Deno so that it uses Nix's certificate authority
      DENO_TLS_CA_STORE = "";
      DENO_CERT = mkForce config.fabriq.casync.path;
      # Don't prompt for updates as Deno is managed by Nix
      DENO_NO_UPDATE_CHECK = "1";
    };
  };

}
