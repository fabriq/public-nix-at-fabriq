{
  description = "Manage an engineer's Macbook at Fabriq with nix-darwin and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { darwin, home-manager, nixpkgs-unstable, ... }: {
    # This must be an attribute sets where keys are device hostnames and values
    # are darwin modules.
    darwinConfigurations =
      let
        # The data on engineers at Fabriq (users) and their laptops (devices).
        data = builtins.fromJSON (builtins.readFile ./data.json);

        # Builds an index of modules so that we don't have to manually list them in a file.
        collectModules = dir:
          builtins.attrValues
            (builtins.mapAttrs
              (file: type: if type == "directory" then "${dir}/${file}/default.nix" else "${dir}/${file}")
              (builtins.readDir dir));

        # We assume that all devices run on Apple Silicon
        system = "aarch64-darwin";

        # Defining a way
        pkgsUnstable = import nixpkgs-unstable { inherit system; };

        # System-level modules shared to everyone
        systemModules = (collectModules ./system_modules);
        # User-level modules shared to everyone
        userModules = (collectModules ./user_modules);

        # The purpose of the fabriq.user module is to allow referencing data
        # that depends on the user, such as their name, email address or
        # username on GitHub.
        # It exists both a system module and as a user module.
        makeFabriqUserModule = { deviceData, userData }: { lib, ... }: with lib;
          {
            options = {
              fabriq.user = {
                username = mkOption {
                  type = types.str;
                  description = "The username in Fabriq's system.";
                };
                emailAddress = mkOption {
                  type = types.str;
                  description = "The Fabriq email address of the user.";
                };
                fullName = mkOption {
                  type = types.str;
                  description = "The user's full name";
                };
                githubUsername = mkOption {
                  type = types.str;
                  description = "The username on GitHub";
                };
                githubId = mkOption {
                  type = types.ints.unsigned;
                  description = "The ID on GitHub";
                };
                macosUsername = mkOption {
                  type = types.str;
                  description = "The username of the main macOS user on the device.";
                };
              };
            };
            config = {
              fabriq.user = {
                username = lib.mkForce deviceData.fabriqUser;
                emailAddress = lib.mkForce deviceData.fabriqUser;
                fullName = lib.mkForce userData.fullName;
                githubUsername = lib.mkForce userData.githubUsername;
                githubId = lib.mkForce userData.githubId;
                macosUsername = lib.mkForce deviceData.macosUsername;
              };
            };
          };

        # Nix-related settings that all devices must have
        nixSettings =
          { config, pkgs, lib, ... }:

          {
            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            system.stateVersion = lib.mkForce 4;

            # Auto upgrade nix package and the daemon service.
            services.nix-daemon.enable = lib.mkForce true;

            nixpkgs = {
              config = { allowUnfree = true; };
            };

            nix.settings = lib.mkForce {
              # Whether to accept nix configuration from a flake without
              # prompting.
              accept-flake-config = true;
              # Whether to allow dirty Git/Mercurial trees.
              allow-dirty = true;
              # Nix automatically detects files in the store that have identical
              # contents, and replaces them with hard links to a single copy.
              # This saves disk space.
              auto-optimise-store = true;
              # This options specifies the Unix group containing the Nix build
              # user accounts. In multi-user Nix installations, builds should
              # not be performed by the Nix account since that would allow users
              # to arbitrarily modify the Nix store and database by supplying
              # specially crafted builders; and they cannot be performed by the
              # calling user since that would allow him/her to influence the
              # build result.
              # Therefore, if this option is non-empty and specifies a valid
              # group, builds will be performed under the user accounts that are
              # a member of the group specified here (as listed in /etc/group).
              # Those user accounts should not be used for any other purpose!
              build-users-group = "nixbld";
              experimental-features = [
                "nix-command" # Unified nix command.
                "flakes" # Flakes support, which we rely on by default.
                "repl-flake" # Allow passing installables to nix repl.
              ];
              # Let sandboxed builds access Rosetta 2.
              extra-sandbox-paths = [ "/System/Library/LaunchDaemons/com.apple.oahd.plist" ];
              # The garbage collector will keep the derivations from which
              # non-garbage store paths were built. Usefuly for querying and
              # traceability.
              keep-derivations = true;
              # The garbage collector will keep the outputs of non-garbage
              # derivations. Useful for debugging.
              keep-outputs = true;
              # Sandbox builds.
              sandbox = true;
              # Prevent non-sandox builds.
              sandbox-fallback = false;
              # Authorize nixos cache.
              substituters = [ "https://cache.nixos.org/" ];
              # Public keys for substituers.
              trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
              # Users with root-like access.
              trusted-users = [ "root" "nix" "@wheel" ];
            };

            # Ensures that zsh and bash set a nix-controlled $PATH.
            programs.zsh.enable = lib.mkForce true;
            programs.bash.enable = lib.mkForce true;

            # By default, Home Manager will install packages in $HOME/.nix-profile, but
            # they can be installed to /etc/profiles with:
            home-manager.useUserPackages = lib.mkForce true;

            # By default, Home Manager uses a private pkgs instance that is configured via
            # the home-manager.users.<name>.nixpkgs options. We set the attribute below to
            # instead use the global pkgs that is configured via the system level nixpkgs 
            # options. This saves an extra Nixpkgs evaluation, adds consistency, and 
            # removes the dependency on NIX_PATH, which is otherwise used for importing
            # Nixpkgs.
            home-manager.useGlobalPkgs = lib.mkForce true;
          };
      in
      builtins.mapAttrs
        (hostname: deviceData:
          let
            userData = data.users.${deviceData.fabriqUser};
            fabriqUserModule = makeFabriqUserModule {
              inherit userData deviceData;
            };
            deviceModulePathIfFolder = ./devices/${hostname}/default.nix;
            deviceModulePathIfFile = ./devices/${hostname}.nix;
            deviceModule =
              if
                builtins.pathExists deviceModulePathIfFolder
              then deviceModulePathIfFolder
              else
                (
                  if builtins.pathExists deviceModulePathIfFile
                  then deviceModulePathIfFile
                  else { ... }: { }
                );
          in
          darwin.lib.darwinSystem {
            inherit system;
            specialArgs = { inherit pkgsUnstable; };
            modules = systemModules ++ [
              fabriqUserModule
              home-manager.darwinModules.home-manager
              nixSettings
              ./common.nix
              ({ lib, ... }: {
                users. users.${ deviceData.macosUsername} = {
                  name = lib.mkForce deviceData.macosUsername;
                  home = lib.mkForce "/Users/${deviceData.macosUsername}";
                  shell = lib.mkDefault "/run/current-system/sw/bin/zsh";
                };
                fabriq.home.modules = [ fabriqUserModule ] ++ userModules;
              })
              deviceModule
            ];
          }
        )
        data.devices;
  };
}
