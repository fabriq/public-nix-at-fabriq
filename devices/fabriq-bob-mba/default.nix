{ config, pkgs, ... }:

{
  imports = [ ./system_packages.nix ];

  security.pam.enableSudoTouchIdAuth = true;

  fabriq.home.modules = [ ./home.nix ];
}
