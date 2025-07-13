# Common modules imported by all hosts
{ ... }: {
  imports = [
    ./base.nix
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./tailscale.nix
    ./hardware.nix
  ];
}