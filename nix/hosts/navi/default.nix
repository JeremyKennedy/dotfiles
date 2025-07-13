# Desktop wrapper - maintains existing configuration unchanged
{
  inputs,
  outputs,
  ...
}: {
  imports = [../../nixos/configuration.nix];
  # No changes - just wrapping existing config
}
