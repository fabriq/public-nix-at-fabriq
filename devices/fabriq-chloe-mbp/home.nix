{ pkgs, lib, ... }:

with lib;

{
  programs.git = {
    extraConfig = {
      push = {
        default = mkDefault "current";
      };
      pull = {
        ff = mkDefault "only";
      };
      init = {
        defaultBranch = mkForce "main";
      };
      color = {
        ui = mkDefault true;
      };
      core = {
        editor = mkDefault "vim";
      };
    };
    aliases = {
      st = "status";
      co = "checkout";
      cm = "commit";
      cma = "commit --amend";
      mg = "merge";
      mgc = "merge --continue";
      mga = "merge --abort";
      rb = "rebase";
      rbi = "rebase --interactive --autosquash";
      rbc = "rebase --continue";
      rba = "rebase --abort";
      cp = "cherry-pick";
      cpc = "cherry-pick --continue";
      sh = "stash";
      shls = "stash list";
      pop = "reset HEAD^";
      hpop = "reset --hard HEAD^";
      cmp = "!f() { git log $1..HEAD --reverse --oneline; }; f";
      cmpr = "!f() { git log HEAD..$1 --reverse --oneline; }; f";
      now = "!f() { GIT_COMMITTER_DATE=\"$(date)\" git commit --amend --no-edit --date \"$(date)\"; }; f";
      b = "checkout -b";
      bb = "branch";
      lb = "branch --sort=-committerdate";
      graph = "log --graph --format=oneline --abbrev-commit";
    };
  };
}
