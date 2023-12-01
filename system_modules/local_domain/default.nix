{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fabriq.localDomain;
  daemonsLogsDirectory = "${cfg.logsDirectory}/daemons";
in

{
  options.fabriq.localDomain = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the local domain.";
    };

    dnsmasq = mkOption {
      type = types.path;
      default = pkgs.dnsmasq;
      defaultText = "pkgs.dnsmasq";
      description = "This option specifies the dnsmasq package to use.";
    };

    socat = mkOption {
      type = types.path;
      default = pkgs.socat;
      defaultText = "pkgs.socat";
      description = "This option specifies the socat package to use.";
    };

    localIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "The IP address to set as a loopback alias, and on which dnsmasq and socat will bind.";
    };

    gatewayIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "The IP address of the Gateway service.";
    };

    gatewayPort = mkOption {
      type = types.int;
      default = 61000;
      description = "The port of the Gateway service.";
    };

    domain = mkOption {
      type = types.str;
      default = "local.test";
      description = "The local domain that should be setup.";
    };

    logsDirectory = mkOption {
      type = types.str;
      default = "/var/log/local-domain";
      description = "The directory in which to store logs";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.preActivation.text =
      ''
        mkdir -p ${cfg.logsDirectory} ${daemonsLogsDirectory}
      '';

    launchd.daemons."local-domain.alias" = mkIf
      (cfg.localIp != "127.0.0.1")
      {
        serviceConfig = {
          ProgramArguments = [ "/sbin/ifconfig" "lo0" "alias" cfg.localIp ];
          RunAtLoad = true;
          Nice = 10;
          KeepAlive = false;
          AbandonProcessGroup = true;
          StandardOutPath = "${daemonsLogsDirectory}/alias/stdout.log";
          StandardErrorPath = "${daemonsLogsDirectory}/alias/stderr.log";
          # It nees to be root only it can create lo0 aliases with ifconfig
          GroupName = "wheel";
          UserName = "root";
        };
      };

    launchd.daemons."local-domain.dnsmasq" = {
      path = [ cfg.dnsmasq ];
      serviceConfig = {
        Program = "${cfg.dnsmasq}/bin/dnsmasq";
        ProgramArguments = [
          "dnsmasq"
          "--listen-address=${cfg.localIp}"
          "--port=53"
          "--address=/fabriq.test/${cfg.localIp}"
          "--keep-in-foreground"
        ];
        KeepAlive = {
          OtherJobEnabled = mkIf (cfg.localIp != "127.0.0.1") {
            "org.nixos.local-domain.alias" = true;
          };
        };
        RunAtLoad = true;
        StandardOutPath = "${daemonsLogsDirectory}/dnsmasq/stdout.log";
        StandardErrorPath = "${daemonsLogsDirectory}/dnsmasq/stderr.log";
        GroupName = "wheel";
        UserName = "root";
      };
    };

    environment.etc."resolver/fabriq.test" = {
      enable = true;
      text = ''
        port 53
        nameserver ${cfg.localIp}
      '';
    };

    launchd.daemons."local-domain.socat" = {
      path = [ cfg.socat ];
      serviceConfig = {
        Program = "${cfg.socat}/bin/socat";
        ProgramArguments = [
          "socat"
          "-D" # Logging information about file descriptors
          "-d" # Logging fatal and error
          "-d" # Logging warning and notice
          "-d" # Logging info
          "-ls" # Logging to stderr
          "TCP4-LISTEN:443,bind=${cfg.localIp},fork,reuseaddr"
          "TCP4:${cfg.gatewayIp}:${toString cfg.gatewayPort},bind=${cfg.gatewayIp}"
        ];
        KeepAlive = {
          OtherJobEnabled = {
            "org.nixos.local-domain.dnsmasq" = true;
          };
        };
        RunAtLoad = true;
        WorkingDirectory = "${pkgs.socat}";
        StandardOutPath = "${daemonsLogsDirectory}/socat/stdout.log";
        StandardErrorPath = "${daemonsLogsDirectory}/socat/stderr.log";
        GroupName = "wheel";
        UserName = "root";
      };
    };

    # Keeping the old ones to ensure that they are deleted
    users.knownUsers = [ "localdomain" "_localdomain" ];
    users.knownGroups = [ "localdomain" "_localdomain" ];
  };
}
