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
      '';
      # https://github.com/nix-community/home-manager/commit/f80df90c105d081a49d123c34a57ead9dac615b9
      # this will come with a future release of home-manager,
      # and will allow us to remove the parts of the funky interactiveShellInit above
      # shellInitLast = ''
      #   # setup any-nix-shell integration
      #   ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      # '';
      shellAbbrs = {
        gh = "ghq";
        g = "git";
        v = "nvim";
        e = "eza";
        nrs = "sudo nixos-rebuild switch";
        nrsu = "sudo nixos-rebuild switch --upgrade";
        t = "ssh tower.lan";
        tower = "ssh tower.lan";
        tdl = "ssh tower.lan docker logs -f";
        tdu = "ssh tower.lan docker start";
        tdd = "ssh tower.lan docker stop";
        tdr = "ssh tower.lan docker restart";
        tde = "ssh tower.lan docker -t exec -it";
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
  };
}
