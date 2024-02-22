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
