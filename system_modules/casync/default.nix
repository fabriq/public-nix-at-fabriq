{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fabriq.casync;
  caexport = pkgs.writeShellApplication {
    name = "caexport";
    text = builtins.readFile ./caexport.sh;
  };
  casync = pkgs.writeShellScriptBin "casync" ''
    if [ "$(id -u)" != "0" ]; then
      echo "casync must be run as root" 1>&2
      exit 1
    fi
    ${caexport}/bin/caexport ${builtins.concatStringsSep " " cfg.keychains} > ${cfg.path}
  '';
in

{
  options.fabriq.casync = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to regularly export trusted certificates from the keychains into the designated file.";
    };

    keychains = mkOption {
      type = types.listOf types.path;
      default = [
        "/Library/Keychains/System.keychain"
        "/System/Library/Keychains/SystemRootCertificates.keychain"
      ];
      description = "The keychains to export trusted certificates from.";
    };

    path = mkOption {
      type = types.path;
      default = "/etc/ssl/certs/ca-certificates.crt";
      description = "The path to export trusted certificates to.";
    };

    frequency = mkOption {
      type = types.int;
      default = 3600;
      description = "How often the export is to be performed, in seconds. Set to zero to export only at boot.";
    };
  };

  config = mkIf cfg.enable {
    security.pki.installCACerts = mkForce false;

    environment.variables =
      {
        NIX_SSL_CERT_FILE = mkForce cfg.path;
        SSL_CERT_FILE = mkForce cfg.path;
        CERT_PATH = mkForce cfg.path;
        REQUESTS_CA_BUNDLE = mkForce cfg.path;
      };

    environment.systemPackages = [ casync ];

    launchd.daemons."casync" = {
      path = [ casync ];
      serviceConfig = {
        ProgramArguments = [ "${casync}/bin/casync" ];
        RunAtLoad = true;
        KeepAlive = false;
        StartInterval = mkIf (cfg.frequency > 0) cfg.frequency;
        GroupName = "wheel";
        UserName = "root";
      };
    };
  };
}
