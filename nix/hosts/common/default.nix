# Common modules imported by all hosts
{ ... }: {
  imports = [
    ./base.nix
    ./boot.nix
    ./performance.nix
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./tailscale.nix
    ./hardware.nix
    ./security.nix
  ];
}