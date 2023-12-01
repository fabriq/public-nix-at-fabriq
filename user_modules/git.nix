{ config, lib, ... }:

with lib;

let
  cfg = config.fabriq.git;
  user = config.fabriq.user;
in

{
  options.fabriq.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable git and its default configuration.";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = mkForce user.fullName;
      userEmail = mkForce "${builtins.toString user.githubId}+${user.githubUsername}@users.noreply.github.com";
      ignores = [ ".DS_Store" ];

      extraConfig = {
        init = {
          # Default to main branch, standard at Fabriq
          defaultBranch = mkForce "main";
        };
        push = {
          # Avoids having to manually match branches when pushing
          default = mkDefault "current";
        };
        pull = {
          # Prevents pulls that do not fast-forward in order to avoid merge
          # commits
          ff = mkDefault "only";
        };
        fetch = {
          # Garbage-collect deleted branches
          prune = mkDefault true;
          # Get everything
          all = mkDefault true;
        };
        color = {
          ui = mkDefault true;
        };
      };
    };
  };
}
