{ config, pkgs, ... }:

{
  security.pam.enableSudoTouchIdAuth = true;

  fabriq.home.modules = [ ./home.nix ];
}
