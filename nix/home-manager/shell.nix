{
  config,
  pkgs,
  ...
}: {
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        any-nix-shell fish --info-right | source

        function fish_greeting
          fortune -a | cowsay -n | lolcat
        end
      '';
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
      settings = {
      };
    };
  };
}
