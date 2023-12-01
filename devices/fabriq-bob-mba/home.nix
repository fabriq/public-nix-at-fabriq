{ pkgs, lib, ... }:

with lib;

{
  programs.zsh = {
    enable = true;
    initExtra = ''
      function dev() {
        cd ~/dev
      }
      if [ -d "''${HOME}/.zshrc.d" ]; then
        for config_file ($HOME/.zshrc.d/*.zsh); do
          source $config_file
        done
      fi
    '';
    shellAliases = {
      ls = "ls --color";
      ll = "ls -l";
      la = "ls -al";
      restart_dnsmasq = "sudo launchctl unload /Library/LaunchDaemons/org.nixos.local-domain.dnsmasq.plist && sudo launchctl load /Library/LaunchDaemons/org.nixos.local-domain.dnsmasq.plist";
    };
    plugins = with pkgs; [
      {
        file = "powerlevel10k.zsh-theme";
        name = "powerlevel10k";
        src = "${zsh-powerlevel10k}/share/zsh-powerlevel10k";
      }
      {
        file = ".p10k.zsh";
        name = "powerlevel10k-config";
        src = cleanSource ./p10k-config;
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "terraform" ];
    };
  };

  programs.git = {
    extraConfig = {
      push = {
        default = mkDefault "current";
      };
      pull = {
        ff = mkDefault "only";
        rebase = mkDefault true;
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
      help = {
        autocorrect = mkDefault 30;
      };
    };
    aliases = {
      l = "log --graph '--pretty=format:%C(auto)%h %s %C(auto)%d%n         %C(magenta)%ar %C(green)%an'";
      f = "fetch --prune --all";
      d = "diff";
      dc = "diff --cached";
      c = "checkout";
      cm = "commit";
      cmm = "commit -m";
      rs = "restore";
      rv = "review";
      s = "status";
      cma = "commit --amend";
      cman = "commit --amend --no-edit";
      addu = "add -u";
    };
  };


  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    extraConfig = ''
      set-option -g default-shell /bin/zsh
      set -g default-terminal "screen-256color"

      bind-key | split-window -h
      bind-key - split-window -v
      bind-key m set-window-option synchronize-panes\; display-message "synchronize-panes is now #{?pane_synchronized,on,off}"

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      setw -g mouse on

      set-window-option -g automatic-rename off
      set-option -g allow-rename off
    '';
  };

}
