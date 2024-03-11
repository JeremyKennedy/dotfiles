{
  config,
  pkgs,
  ...
}: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        # salty greeting
        function fish_greeting
          fortune -a | cowsay -n | lolcat
        end

        # init starship prompt
        # we do this manually to avoid the starship init script from preventing
        # the any-nix-shell integration from showing info on the right
        ${pkgs.starship}/bin/starship init fish | source

        # init any-nix-shell integration
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

        # don't add spaces at end of abbrs unless explicitly defined in the abbr
        bind " " expand-abbr or self-insert
      '';
      # https://github.com/nix-community/home-manager/commit/f80df90c105d081a49d123c34a57ead9dac615b9
      # this will come with a future release of home-manager,
      # and will allow us to remove the parts of the funky interactiveShellInit above
      # shellInitLast = ''
      #   # setup any-nix-shell integration
      #   ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      # '';
      shellAbbrs = {
        gh = "ghq ";
        g = "git ";
        v = "nvim ";
        e = "eza ";
        tree = "tre ";

        nr = "sudo nixos-rebuild switch";
        nru = "sudo nixos-rebuild switch --upgrade";

        t = "ssh tower.lan -t fish";
        tower = "ssh tower.lan -t fish";
        tdl = "ssh tower.lan docker logs -f ";
        tdu = "ssh tower.lan docker start ";
        tdd = "ssh tower.lan docker stop ";
        tdr = "ssh tower.lan docker restart ";
        tde = "ssh tower.lan -t docker exec -it ";

        run = "nix run nixpkgs#";
        shell = "nix shell nixpkgs#";

        modown = "sudo chmod 777 -R . ; sudo chown -R jeremy:users . ; ll";

        ha = "hass-cli ";
      };
      plugins = [
        {
          name = "z";
          src = pkgs.fishPlugins.z.src;
        }
      ];
    };

    starship = {
      enable = true;
      # neede for any-nix-shell integration to show info on the right
      enableFishIntegration = false;
      settings = {
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          dimensions = {
            columns = 120;
            lines = 40;
          };
          opacity = 0.9;
          decorations = "none";
        };
      };
    };

    zellij = {
      enable = true;
      enableFishIntegration = true;
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    eza = {
      enable = true;
      enableAliases = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultCommand = "${pkgs.ripgrep}/bin/rg --files --follow 2> /dev/null";
      # ctrl-t
      fileWidgetCommand = "${pkgs.ripgrep}/bin/rg --files --follow 2> /dev/null";
      # alt-c
      changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d 2> /dev/null";
    };
  };
}
