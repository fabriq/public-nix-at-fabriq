{ config, lib, ... }:

with lib;

let
  cfg = config.fabriq.home;
in

{
  options.fabriq.home = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable home manager for the main user of the device.";
    };
    modules = mkOption {
      type = types.listOf types.deferredModule;
      description = "Home manager modules to import";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.fabriq.user.macosUsername} = ({ lib, ... }: {
      imports = cfg.modules;
      home.stateVersion = lib.mkDefault "22.11";
    });
  };
}
