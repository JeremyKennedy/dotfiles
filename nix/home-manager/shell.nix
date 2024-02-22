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
        nrsu = "sudo nixos-rebuild switch";
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
