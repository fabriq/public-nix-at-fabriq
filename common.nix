# This Nix expression is the common device configuration loaded for all devices.

{ config, pkgs, ... }:

let
  userConfig = { ... }: {
    fabriq = {
      git = {
        enable = true;
      };
    };
  };
in

{
  fabriq = {
    home = {
      enable = true;
      modules = [ userConfig ];
    };

    commonPackages = {
      enable = true;
    };

    casync = {
      enable = true;
    };

    localDomain = {
      enable = true;
      localIp = "127.0.0.61";
      domain = "fabriq.test";
    };
  };
}

