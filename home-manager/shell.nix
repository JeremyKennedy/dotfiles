{
  config,
  pkgs,
  ...
}: let
  inherit (import ../modules/core/hosts.nix) hosts;
in {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # salty greeting
        function fish_greeting
          fortune -a | cowsay -n | lolcat
        end

        # starship and any-nix-shell now handled by core

        # don't add spaces at end of abbrs unless explicitly defined in the abbr
        # bind " " expand-abbr or self-insert
      '';
      # https://github.com/nix-community/home-manager/commit/f80df90c105d081a49d123c34a57ead9dac615b9
      # this will come with a future release of home-manager,
      # and will allow us to remove the parts of the funky interactiveShellInit above
      # shellInitLast = ''
      #   # setup any-nix-shell integration
      #   ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      # '';
      shellAbbrs = {
        # Core abbreviations handled in core/shell.nix
        # Keep only user-specific ones here
        co = "gh copilot";

        # Navigation aliases using zoxide
        cd = "z"; # Use zoxide for navigation
        cdi = "zi"; # Interactive directory selection with zoxide

        # Server shortcuts (user-specific)
        t = "ssh ${hosts.tower.ip} -t fish";
        tower = "ssh ${hosts.tower.ip} -t fish";
        tdl = "ssh ${hosts.tower.ip} docker logs -f";
        tdu = "ssh ${hosts.tower.ip} docker start";
        tdd = "ssh ${hosts.tower.ip} docker stop";
        tdr = "ssh ${hosts.tower.ip} docker restart";
        tde = "ssh ${hosts.tower.ip} -t docker exec -it";

        # User-specific shortcuts
        modown = "sudo chmod 777 -R . ; sudo chown -R jeremy:users . ; ll";
        ha = "hass-cli";
      };
      plugins = [
        # Removed z plugin - using zoxide from core instead
      ];
    };

    # starship now configured in core modules

    alacritty = {
      enable = true;
      settings = {
        window = {
          # dimensions = {
          #   columns = 120;
          #   lines = 40;
          # };
          # opacity = 0.9;
          # decorations = "none";
        };
        env = {
          TERM = "xterm-256color";
        };
      };
    };

    # zellij = {
    #   enable = true;
    #   enableFishIntegration = true;
    # };

    # neovim, eza, fzf now configured in core modules
  };
}
