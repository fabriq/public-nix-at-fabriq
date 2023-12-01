{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    fzf
    meslo-lgs-nf
    gh
  ];
}
